import Foundation

public struct WebClientHTML {
    public static let content: String = """
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no, viewport-fit=cover">
    <meta name="apple-mobile-web-app-capable" content="yes">
    <meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">
    <meta name="apple-mobile-web-app-title" content="OpenScreen">
    <title>iPhone Extended Display - iPhone Monitor</title>
    <style>
        * {
            box-sizing: border-box;
            margin: 0;
            padding: 0;
            user-select: none;
            -webkit-user-select: none;
            touch-action: none;
        }
        body, html {
            width: 100%;
            height: 100%;
            height: 100dvh;
            overflow: hidden;
            background-color: #000;
            color: #fff;
            font-family: -apple-system, BlinkMacSystemFont, "SF Pro Text", "SF Pro Display", sans-serif;
        }
        #canvas-wrapper {
            position: absolute;
            top: 0;
            left: 0;
            width: 100vw;
            height: 100vh;
            height: 100dvh;
            display: flex;
            align-items: center;
            justify-content: center;
            background: #000;
        }
        #canvas {
            width: 100%;
            height: 100%;
            object-fit: contain;
            display: block;
        }
        #canvas.fill-mode {
            object-fit: fill;
        }
        /* HUD Badge: Dikecilkan & Auto-Hide */
        #hud {
            position: absolute;
            top: env(safe-area-inset-top, 8px);
            right: env(safe-area-inset-right, 8px);
            background: rgba(0, 0, 0, 0.45);
            backdrop-filter: blur(8px);
            -webkit-backdrop-filter: blur(8px);
            border: 1px solid rgba(255, 255, 255, 0.15);
            padding: 3px 8px;
            border-radius: 12px;
            font-size: 9px;
            font-weight: 600;
            color: #34c759;
            z-index: 50;
            pointer-events: none;
            opacity: 0;
            transition: opacity 0.4s ease;
        }
        #hud.visible {
            opacity: 0.85;
        }

        /* Control Pill: Dikecilkan, Elegan & Auto-Hide */
        #control-pill {
            position: absolute;
            bottom: max(env(safe-area-inset-bottom, 10px), 10px);
            left: 50%;
            transform: translateX(-50%);
            background: rgba(20, 20, 25, 0.8);
            backdrop-filter: blur(14px);
            -webkit-backdrop-filter: blur(14px);
            border: 1px solid rgba(255, 255, 255, 0.15);
            border-radius: 20px;
            padding: 4px 8px;
            display: flex;
            align-items: center;
            gap: 4px;
            z-index: 60;
            opacity: 0;
            pointer-events: none;
            transition: opacity 0.4s ease, transform 0.3s ease;
        }
        #control-pill.visible {
            opacity: 0.85;
            pointer-events: auto;
        }
        #control-pill:hover {
            opacity: 1;
        }

        .pill-btn {
            background: none;
            border: none;
            color: #d1d1d6;
            font-size: 11px;
            font-weight: 500;
            cursor: pointer;
            padding: 4px 8px;
            border-radius: 10px;
            display: flex;
            align-items: center;
            gap: 3px;
        }
        .pill-btn:active {
            background: rgba(255, 255, 255, 0.12);
            color: #fff;
        }

        /* Tombol Mengambang Mini (Discreet Trigger) di Pojok */
        #toggle-menu-btn {
            position: absolute;
            bottom: max(env(safe-area-inset-bottom, 8px), 8px);
            right: max(env(safe-area-inset-right, 8px), 8px);
            background: rgba(255, 255, 255, 0.08);
            backdrop-filter: blur(10px);
            -webkit-backdrop-filter: blur(10px);
            border: 1px solid rgba(255, 255, 255, 0.1);
            color: rgba(255, 255, 255, 0.4);
            width: 28px;
            height: 28px;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 12px;
            z-index: 55;
            cursor: pointer;
            transition: opacity 0.3s, background 0.2s;
        }
        #toggle-menu-btn:active {
            background: rgba(255, 255, 255, 0.25);
            color: #fff;
        }

        /* Modal Petunjuk Layar Penuh iOS */
        #fullscreen-modal {
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            background: rgba(0, 0, 0, 0.85);
            backdrop-filter: blur(15px);
            -webkit-backdrop-filter: blur(15px);
            z-index: 200;
            display: none;
            align-items: center;
            justify-content: center;
            padding: 20px;
        }
        .modal-box {
            background: #1c1c1e;
            border: 1px solid rgba(255, 255, 255, 0.18);
            border-radius: 20px;
            padding: 22px;
            max-width: 340px;
            width: 100%;
            text-align: center;
            box-shadow: 0 20px 50px rgba(0,0,0,0.8);
        }
        .modal-icon {
            font-size: 34px;
            margin-bottom: 10px;
        }
        .modal-title {
            font-size: 17px;
            font-weight: 700;
            margin-bottom: 8px;
            color: #fff;
        }
        .modal-desc {
            font-size: 12.5px;
            color: #a0a0a8;
            line-height: 1.5;
            margin-bottom: 18px;
            text-align: left;
        }
        .step-item {
            display: flex;
            align-items: flex-start;
            gap: 10px;
            margin-bottom: 10px;
            font-size: 12.5px;
            color: #e5e5ea;
        }
        .step-num {
            background: #0071e3;
            color: white;
            width: 20px;
            height: 20px;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 10px;
            font-weight: 700;
            flex-shrink: 0;
        }
        .btn-modal {
            background: #0071e3;
            color: white;
            border: none;
            padding: 11px 18px;
            font-size: 13.5px;
            font-weight: 600;
            border-radius: 10px;
            width: 100%;
            cursor: pointer;
            margin-top: 6px;
        }
        #overlay {
            position: absolute;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            display: flex;
            flex-direction: column;
            justify-content: center;
            align-items: center;
            background: rgba(10, 10, 15, 0.94);
            backdrop-filter: blur(20px);
            -webkit-backdrop-filter: blur(20px);
            z-index: 100;
            transition: opacity 0.3s ease;
            padding: 24px;
            text-align: center;
        }
        .card {
            background: rgba(255, 255, 255, 0.08);
            border: 1px solid rgba(255, 255, 255, 0.15);
            border-radius: 20px;
            padding: 28px 24px;
            max-width: 360px;
            width: 100%;
            box-shadow: 0 20px 40px rgba(0,0,0,0.5);
        }
        h1 {
            font-size: 20px;
            font-weight: 700;
            margin-bottom: 8px;
            color: #fff;
        }
        p {
            font-size: 13px;
            color: #a0a0a8;
            margin-bottom: 20px;
            line-height: 1.4;
        }
        .btn {
            background: #0071e3;
            color: white;
            border: none;
            padding: 14px 28px;
            font-size: 16px;
            font-weight: 600;
            border-radius: 12px;
            width: 100%;
            cursor: pointer;
            transition: transform 0.1s, background 0.2s;
        }
        .btn:active {
            transform: scale(0.97);
            background: #0077ed;
        }
        .badge {
            display: inline-block;
            background: rgba(52, 199, 89, 0.2);
            color: #34c759;
            padding: 4px 10px;
            border-radius: 20px;
            font-size: 11px;
            font-weight: 600;
            margin-bottom: 16px;
        }
    </style>
</head>
<body>
    <div id="canvas-wrapper">
        <canvas id="canvas"></canvas>
    </div>

    <!-- Badge HUD: Kecil & Otomatis Sembunyi -->
    <div id="hud">60 FPS • Terhubung</div>

    <!-- Tombol Pemicu Menu Mini (Hanya sebuah titik kecil di pojok kanan bawah) -->
    <div id="toggle-menu-btn" onclick="toggleMenu()" title="Pengaturan">⚙</div>

    <!-- Floating Navigation Pill: Minimalis & Auto-Hide -->
    <div id="control-pill">
        <button class="pill-btn" onclick="toggleFullscreen()">⛶ Layar Penuh</button>
        <button class="pill-btn" id="aspectBtn" onclick="toggleAspect()">↔ Penuhi</button>
        <button class="pill-btn" onclick="location.reload()">↺ Refresh</button>
        <button class="pill-btn" onclick="hideControlsImmediately()" style="color:#8e8e93;">✕</button>
    </div>

    <!-- Modal Petunjuk Layar Penuh iPhone -->
    <div id="fullscreen-modal" onclick="closeModal(event)">
        <div class="modal-box" onclick="event.stopPropagation()">
            <div class="modal-icon">📲</div>
            <div class="modal-title">Mode Layar Penuh iPhone</div>
            <div class="modal-desc">
                Safari di iPhone menyembunyikan tombol fullscreen browser.<br>
                Gunakan fitur resmi <b>Web App Apple</b> untuk tampilan 100% penuh tanpa bilah URL:
                <br><br>
                <div class="step-item">
                    <div class="step-num">1</div>
                    <div>Ketuk tombol <b>Bagikan (Share / Ikon Kotak Panah)</b> di bilah bawah Safari.</div>
                </div>
                <div class="step-item">
                    <div class="step-num">2</div>
                    <div>Gulir ke bawah dan pilih <b>"Tambah ke Layar Utama" (Add to Home Screen)</b>.</div>
                </div>
                <div class="step-item">
                    <div class="step-num">3</div>
                    <div>Buka ikon di Home Screen iPhone Anda. Tampilan akan langsung <b>100% Layar Penuh Murni</b>!</div>
                </div>
            </div>
            <button class="btn-modal" onclick="closeModal()">Mengerti</button>
        </div>
    </div>

    <!-- Welcome Overlay -->
    <div id="overlay">
        <div class="card">
            <span class="badge">● Terhubung</span>
            <h1>iPhone XR Extended Monitor</h1>
            <p>Jadikan iPhone Anda sebagai monitor kedua untuk Mac Anda.</p>
            <button class="btn" id="startBtn" onclick="startStream()">Mulai Layar Tambahan</button>
            <p style="margin-top: 16px; margin-bottom: 0; font-size: 11px; color: #888;">
                Tip: Menu akan otomatis tersembunyi agar layar bersih. Ketuk ikon ⚙ di pojok untuk menampilkan menu.
            </p>
        </div>
    </div>

    <script>
        const canvas = document.getElementById('canvas');
        const ctx = canvas.getContext('2d');
        const overlay = document.getElementById('overlay');
        const hud = document.getElementById('hud');
        const controlPill = document.getElementById('control-pill');
        const toggleMenuBtn = document.getElementById('toggle-menu-btn');
        const aspectBtn = document.getElementById('aspectBtn');
        const fullscreenModal = document.getElementById('fullscreen-modal');

        let ws = null;
        let frameCount = 0;
        let lastFpsUpdate = performance.now();
        let isFillMode = false;
        let hideTimeout = null;

        function startStream() {
            overlay.style.opacity = '0';
            setTimeout(() => { overlay.style.display = 'none'; }, 300);

            // Auto-scroll to collapse Safari address bar
            window.scrollTo(0, 1);

            // Tampilkan HUD dan kontrol sebentar selama 2.5 detik lalu sembunyikan otomatis
            showControlsTemporarily(2500);

            connectWebSocket();
        }

        // Tampilkan kontrol sementara (auto-hide)
        function showControlsTemporarily(durationMs = 3000) {
            hud.classList.add('visible');
            controlPill.classList.add('visible');
            toggleMenuBtn.style.opacity = '0.7';

            if (hideTimeout) clearTimeout(hideTimeout);
            hideTimeout = setTimeout(() => {
                hideControlsImmediately();
            }, durationMs);
        }

        function hideControlsImmediately() {
            hud.classList.remove('visible');
            controlPill.classList.remove('visible');
            toggleMenuBtn.style.opacity = '0.2';
            if (hideTimeout) clearTimeout(hideTimeout);
        }

        function toggleMenu() {
            if (controlPill.classList.contains('visible')) {
                hideControlsImmediately();
            } else {
                showControlsTemporarily(4000);
            }
        }

        function connectWebSocket() {
            const loc = window.location;
            const wsProto = loc.protocol === 'https:' ? 'wss:' : 'ws:';
            const wsUrl = `${wsProto}//${loc.host}/ws`;

            ws = new WebSocket(wsUrl);
            ws.binaryType = 'arraybuffer';

            ws.onopen = () => {
                const scale = window.devicePixelRatio || 2.0;
                const width = Math.round(window.innerWidth);
                const height = Math.round(window.innerHeight);

                ws.send(JSON.stringify({
                    type: 'handshake',
                    width: width,
                    height: height,
                    scale: scale,
                    name: 'iPhone XR Web'
                }));
            };

            ws.onmessage = (event) => {
                if (event.data instanceof ArrayBuffer) {
                    renderFrame(event.data);
                }
            };

            ws.onclose = () => {
                hud.style.color = '#ff9500';
                hud.innerText = 'Menyambung ulang...';
                showControlsTemporarily(3000);
                setTimeout(connectWebSocket, 1500);
            };
        }

        function renderFrame(arrayBuffer) {
            const blob = new Blob([arrayBuffer], { type: 'image/jpeg' });
            
            if (window.createImageBitmap) {
                createImageBitmap(blob).then(bitmap => {
                    if (canvas.width !== bitmap.width || canvas.height !== bitmap.height) {
                        canvas.width = bitmap.width;
                        canvas.height = bitmap.height;
                    }
                    ctx.drawImage(bitmap, 0, 0);
                    bitmap.close();
                    updateFps();
                }).catch(() => fallbackRender(blob));
            } else {
                fallbackRender(blob);
            }
        }

        function fallbackRender(blob) {
            const img = new Image();
            const url = URL.createObjectURL(blob);
            img.onload = () => {
                if (canvas.width !== img.width || canvas.height !== img.height) {
                    canvas.width = img.width;
                    canvas.height = img.height;
                }
                ctx.drawImage(img, 0, 0);
                URL.revokeObjectURL(url);
                updateFps();
            };
            img.src = url;
        }

        function updateFps() {
            frameCount++;
            const now = performance.now();
            if (now - lastFpsUpdate >= 1000) {
                const fps = Math.round((frameCount * 1000) / (now - lastFpsUpdate));
                hud.style.color = '#34c759';
                hud.innerText = `${fps} FPS`;
                frameCount = 0;
                lastFpsUpdate = now;
            }
        }

        function toggleFullscreen() {
            if (window.navigator.standalone) {
                return;
            }

            const docEl = document.documentElement;
            const requestFS = docEl.requestFullscreen || docEl.webkitRequestFullscreen || docEl.mozRequestFullScreen;

            if (requestFS) {
                requestFS.call(docEl).catch(() => { showModal(); });
            } else {
                showModal();
            }
        }

        function toggleAspect() {
            isFillMode = !isFillMode;
            if (isFillMode) {
                canvas.classList.add('fill-mode');
                aspectBtn.innerText = '↔ Pas';
            } else {
                canvas.classList.remove('fill-mode');
                aspectBtn.innerText = '↔ Penuhi';
            }
            showControlsTemporarily(2000);
        }

        function showModal() {
            fullscreenModal.style.display = 'flex';
        }

        function closeModal() {
            fullscreenModal.style.display = 'none';
        }

        // Touch Input Mapping
        function handleTouch(phase, event) {
            if (!ws || ws.readyState !== WebSocket.OPEN) return;
            const touches = event.touches;
            if (touches.length === 0 && phase !== 3) return;

            const touch = phase === 3 ? (event.changedTouches[0] || {}) : touches[0];
            const rect = canvas.getBoundingClientRect();
            
            const normX = Math.max(0.0, Math.min(1.0, (touch.clientX - rect.left) / rect.width));
            const normY = Math.max(0.0, Math.min(1.0, (touch.clientY - rect.top) / rect.height));
            const isRightClick = event.touches ? event.touches.length > 1 : false;

            ws.send(JSON.stringify({
                type: 'touch',
                phase: phase,
                x: normX,
                y: normY,
                rightClick: isRightClick
            }));
        }

        canvas.addEventListener('touchstart', (e) => { e.preventDefault(); handleTouch(0, e); }, { passive: false });
        canvas.addEventListener('touchmove',  (e) => { e.preventDefault(); handleTouch(1, e); }, { passive: false });
        canvas.addEventListener('touchend',   (e) => { e.preventDefault(); handleTouch(3, e); }, { passive: false });
        canvas.addEventListener('touchcancel', (e) => { e.preventDefault(); handleTouch(3, e); }, { passive: false });

        window.addEventListener('orientationchange', () => {
            setTimeout(() => { window.scrollTo(0, 1); }, 200);
        });
    </script>
</body>
</html>
"""
}
