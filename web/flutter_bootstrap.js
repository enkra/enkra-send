{{flutter_js}}
{{flutter_build_config}}

setTimeout(function()  {
  const loading = document.querySelector('#loading');
  loading.style.visibility = "visible";
}, 600);

_flutter.loader.load({
  serviceWorkerSettings: {
    serviceWorkerVersion: {{flutter_service_worker_version}}
  },
  config: {
    canvasKitBaseUrl: "./canvaskit/"
  },
  onEntrypointLoaded: async (engineInitializer) => {
    // after flutter entrypoint downloaded
    const appRunner = await engineInitializer.initializeEngine({});
    await appRunner.runApp();

    setTimeout(function()  {
      const container = document.querySelector('#container');
      container.remove();
    }, 2000);

    // prefetch resources
    _loadScript("https://cdn.jsdelivr.net/npm/jsqr@1.3.1/dist/jsQR.min.js");
    fetch("/");
  },
}).then(() => {
  // after Service Worker is initialized

  fetch("assets/FontManifest.json");
  fetch("assets/fonts/MaterialIcons-Regular.otf");
  fetch("/pkg/rust_lib_enkra_send.js");
  fetch("/pkg/rust_lib_enkra_send_bg.wasm");
});

function _loadScript(url) {
  const scriptTag = document.createElement("script");
  scriptTag.type = "application/javascript";
  scriptTag.src = url;
  document.body.append(scriptTag);
}
