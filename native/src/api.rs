use std::ops::DerefMut;

use anyhow::{anyhow, Result};
use flutter_rust_bridge::RustOpaque;
use hpke::{
    aead::ExportOnlyAead, kdf::HkdfSha256, kem::X25519HkdfSha256, Deserializable, Kem, OpModeR,
    OpModeS, Serializable,
};
use rand::SeedableRng;
use tink_core::Aead;

pub use rand::rngs::StdRng;
pub use std::sync::Mutex;
pub use tink_aead::subtle::XChaCha20Poly1305;

pub struct EnkraSecureChannelKey {
    private_key: <X25519HkdfSha256 as Kem>::PrivateKey,
    public_key: <X25519HkdfSha256 as Kem>::PublicKey,
}

pub struct EncappedKey {
    pub encapsulated_key: Vec<u8>,
    pub shared_secret: AeadCipher,
}

pub struct AeadCipher {
    pub inner: RustOpaque<XChaCha20Poly1305>,
}

impl AeadCipher {
    fn new(key: &[u8]) -> Result<AeadCipher> {
        let aead = XChaCha20Poly1305::new(key).map_err(|e| anyhow!("Aead new failed {}", e))?;

        Ok(AeadCipher {
            inner: RustOpaque::new(aead),
        })
    }

    pub fn encrypt(&self, pt: Vec<u8>, aad: Vec<u8>) -> Result<Vec<u8>> {
        let r = self
            .inner
            .encrypt(&pt, &aad)
            .map_err(|e| anyhow!("encrypt failed {}", e))?;

        Ok(r)
    }

    pub fn decrypt(&self, ct: Vec<u8>, aad: Vec<u8>) -> Result<Vec<u8>> {
        let r = self
            .inner
            .decrypt(&ct, &aad)
            .map_err(|e| anyhow!("decrypt failed {}", e))?;

        Ok(r)
    }
}

pub struct SecureChannelCipher {
    pub key: RustOpaque<EnkraSecureChannelKey>,
    pub csprng: RustOpaque<Mutex<StdRng>>,
}

impl SecureChannelCipher {
    const INFO_STRING: &'static [u8] = b"Enkra Send secure channel";
    const EXPORT_STRING: &'static [u8] = b"Enkra Send secure channel export for aead";

    pub fn new_random() -> SecureChannelCipher {
        let mut csprng = StdRng::from_entropy();

        let (private_key, public_key) = X25519HkdfSha256::gen_keypair(&mut csprng);

        SecureChannelCipher {
            key: RustOpaque::new(EnkraSecureChannelKey {
                private_key,
                public_key,
            }),
            csprng: RustOpaque::new(Mutex::new(csprng)),
        }
    }

    pub fn public(&self) -> Vec<u8> {
        self.key.public_key.to_bytes().to_vec()
    }

    pub fn encap_key(&self, public: Vec<u8>) -> Result<EncappedKey> {
        let public_key = <X25519HkdfSha256 as Kem>::PublicKey::from_bytes(&public)
            .map_err(|e| anyhow!("invalid public key {}", e))?;

        let (encapsulated_key, encryption_context) = {
            let mut csprng = self
                .csprng
                .lock()
                .map_err(|e| anyhow!("csprng lock failed {}", e))?;

            hpke::setup_sender::<ExportOnlyAead, HkdfSha256, X25519HkdfSha256, _>(
                &OpModeS::Base,
                &public_key,
                Self::INFO_STRING,
                csprng.deref_mut(),
            )
            .map_err(|e| anyhow!("invalid receiver pubkey {}", e))?
        };

        let mut export_secret = vec![0; 32];

        encryption_context
            .export(Self::EXPORT_STRING, &mut export_secret)
            .map_err(|e| anyhow!("failed to export key {}", e))?;

        let aead = AeadCipher::new(&export_secret)?;

        Ok(EncappedKey {
            encapsulated_key: encapsulated_key.to_bytes().to_vec(),
            shared_secret: aead,
        })
    }

    pub fn shared_secret(&self, encapsulated_key: Vec<u8>) -> Result<AeadCipher> {
        let encapsulated_key =
            <X25519HkdfSha256 as Kem>::EncappedKey::from_bytes(&encapsulated_key)
                .map_err(|e| anyhow!("invalid encapsulated key {}", e))?;

        let encryption_context =
            hpke::setup_receiver::<ExportOnlyAead, HkdfSha256, X25519HkdfSha256>(
                &OpModeR::Base,
                &self.key.private_key,
                &encapsulated_key,
                Self::INFO_STRING,
            )
            .map_err(|e| anyhow!("invalid sender key {}", e))?;

        let mut export_secret = vec![0; 32];

        encryption_context
            .export(Self::EXPORT_STRING, &mut export_secret)
            .map_err(|e| anyhow!("failed to export key {}", e))?;

        let aead = AeadCipher::new(&export_secret)?;

        Ok(aead)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn it_works() {
        let alice = SecureChannelCipher::new_random();
        let bob = SecureChannelCipher::new_random();

        let bob_pub = bob.public();

        let EncappedKey {
            encapsulated_key: encap_key,
            shared_secret: shared_secret1,
        } = alice.encap_key(bob_pub.clone()).unwrap();

        let shared_secret2 = bob.shared_secret(encap_key).unwrap();

        let text = b"this is a secret message".to_vec();
        let ciphertext = shared_secret1
            .encrypt(text.clone(), b"test".to_vec())
            .unwrap();
        let plaintext = shared_secret2
            .decrypt(ciphertext, b"test".to_vec())
            .unwrap();

        assert_eq!(text, plaintext);
    }
}
