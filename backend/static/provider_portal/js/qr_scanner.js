/**
 * FitZone QR Scanner Logic
 * Separated for DRY compliance. Relies on window.FIT_ZONE_QR_CONFIG for translations/URLs.
 */

'use strict';

document.addEventListener("DOMContentLoaded", function() {
    let scanner = null;
    let isProcessing = false; 
    let isScannerLocked = false; // HARD LOCK: Prevents any scans during an Access Denied state
    const cfg = window.FIT_ZONE_QR_CONFIG; 

    const overlay = document.getElementById('mainOverlay');
    const openBtn = document.getElementById('openBtn');
    const closeBtn = document.getElementById('closeBtn');
    
    const waitingState = document.getElementById('waitingState');
    const dataState = document.getElementById('dataState');
    const guardOverlay = document.getElementById('guardOverlay');
    const dismissGuardBtn = document.getElementById('dismissGuardBtn');

    const idThumb = document.getElementById('resIdCardThumb');
    const zoomModal = document.getElementById('zoomModal');
    const zoomedImg = document.getElementById('zoomedImg');

    idThumb.addEventListener('click', function() {
        if (this.src && !this.src.includes('svg')) {
            zoomedImg.src = this.src;
            zoomModal.style.display = 'flex';
        }
    });
    zoomModal.addEventListener('click', () => zoomModal.style.display = 'none');

    function playNativeBeep(type) {
        try {
            const ctx = new (window.AudioContext || window.webkitAudioContext)();
            const osc = ctx.createOscillator();
            const gainNode = ctx.createGain();
            osc.connect(gainNode); gainNode.connect(ctx.destination);
            
            if (type === 'error') {
                osc.type = 'sawtooth'; osc.frequency.setValueAtTime(150, ctx.currentTime);
                gainNode.gain.setValueAtTime(0.5, ctx.currentTime);
                osc.start(); osc.stop(ctx.currentTime + 0.4);
            } else {
                osc.type = 'sine'; osc.frequency.setValueAtTime(880, ctx.currentTime);
                gainNode.gain.setValueAtTime(0.5, ctx.currentTime);
                osc.start(); osc.stop(ctx.currentTime + 0.15);
            }
        } catch(e) {}
    }

    function startScanner() {
        waitingState.style.display = 'flex';
        dataState.style.display = 'none';
        guardOverlay.classList.remove('show');
        isProcessing = false;
        isScannerLocked = false; // Reset the physical lock when opening the scanner
        
        if (!scanner) {
            scanner = new Html5Qrcode("reader");
        }

        Html5Qrcode.getCameras().then(devices => {
            if (devices && devices.length > 0) {
                let camId = devices[0].id;
                for (let d of devices) if (d.label.toLowerCase().includes('back')) camId = d.id;
                
                const config = { 
                    fps: 10, qrbox: { width: 250, height: 250 },
                    videoConstraints: { width: { ideal: 1280 }, height: { ideal: 720 }, advanced: [{ focusMode: "continuous" }] }
                };
                
                if (scanner.isScanning) {
                    scanner.stop().then(() => startActualScan(camId, config)).catch(err => console.log(err));
                } else {
                    startActualScan(camId, config);
                }
            }
        }).catch(err => { alert(cfg.textCamRequired); });
    }
    
    function startActualScan(camId, config) {
         scanner.start(camId, config, onScanSuccess, () => {}).catch(err => {
             scanner.start(camId, { fps: 10, qrbox: { width: 200, height: 200 } }, onScanSuccess, () => {});
         });
    }

    function onScanSuccess(decodedText) {
        // --- STRICT HARD LOCK CHECK ---
        // If locked due to an error, absolutely ignore all incoming frames.
        if (isScannerLocked || isProcessing) return; 
        
        let cleanText = decodedText.trim();
        if (!cleanText.startsWith("FZ-SUB-")) return; 

        isProcessing = true;

        fetch(cfg.apiUrl, {
            method: "POST",
            headers: { "Content-Type": "application/json", "X-CSRFToken": cfg.csrfToken },
            body: JSON.stringify({ qr_code: cleanText })
        })
        .then(res => res.json())
        .then(data => {
            if(data.status === 'ignore') { isProcessing = false; return; }
            playNativeBeep(data.status_color === 'error' ? 'error' : 'success');
            renderData(data);
        }).catch(err => {
            playNativeBeep('error'); 
            isProcessing = false;
        });
    }

    function renderData(data) {
        waitingState.style.display = 'none';
        dataState.style.display = 'flex';
        guardOverlay.classList.remove('show', 'error', 'warning');

        document.getElementById('resName').textContent = data.member_name || cfg.textUnknown;
        document.getElementById('resMemberId').textContent = data.member_id || "-";
        document.getElementById('resGender').textContent = data.gender || "-";
        document.getElementById('resPhone').textContent = data.phone_number || "-";
        document.getElementById('resAddress').textContent = `${data.city || ""}, ${data.address || "-"}`;
        
        document.getElementById('resAvatar').src = data.avatar_url || 'data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" width="100" height="100" fill="%23cbd5e1" viewBox="0 0 24 24"><path d="M12 12c2.21 0 4-1.79 4-4s-1.79-4-4-4-4 1.79-4 4 1.79 4 4 4zm0 2c-2.67 0-8 1.34-8 4v2h16v-2c0-2.66-5.33-4-8-4z"/></svg>';
        document.getElementById('resIdCardThumb').src = data.id_card_url || 'data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" width="100" height="100" fill="%23cbd5e1" viewBox="0 0 24 24"><rect x="3" y="4" width="18" height="18" rx="2" ry="2"/></svg>';

        document.getElementById('resBranches').textContent = data.allowed_branches || "-";
        document.getElementById('resBranchAddress').textContent = data.branch_address || "-";
        
        const logoImg = document.getElementById('resBranchLogo');
        if(data.branch_logo_url) {
            logoImg.src = data.branch_logo_url;
            logoImg.style.display = 'block';
        } else {
            logoImg.style.display = 'none';
        }

        document.getElementById('resPlan').textContent = data.plan_name || "-";
        document.getElementById('resPlanPrice').textContent = data.plan_price ? `${data.plan_price} SAR` : "-";

        const statusBox = document.getElementById('statusBox');
        statusBox.className = `status-card ${data.status_color}`;
        document.getElementById('resTitle').textContent = data.title;
        document.getElementById('resMsg').textContent = data.message;
        document.getElementById('iconWait').style.display = 'none';
        document.getElementById('iconSuccess').style.display = data.status_color === 'success' ? 'block' : 'none';
        document.getElementById('iconError').style.display = (data.status_color === 'error' || data.status_color === 'warning') ? 'block' : 'none';

        if (data.status_color !== 'error' && data.total_days) {
            const left = data.days_left || 0;
            const total = data.total_days || 1;
            const pct = Math.max(0, Math.min(100, (left / total) * 100));
            document.getElementById('resDaysLeft').textContent = left;
            const chart = document.getElementById('resChart');
            chart.style.setProperty('--progress', `${pct}%`);
            chart.style.background = `conic-gradient(var(--color-${data.status_color === 'warning' ? 'warning' : 'primary'}) var(--progress), var(--color-bg) 0deg)`;
        }

        if (data.status_color !== 'error') {
            document.getElementById('logsSection').style.display = 'flex';
            document.getElementById('resCapacity').textContent = data.current_capacity || "1";
            
            const track = document.getElementById('resTimelineList');
            track.innerHTML = ''; 
            
            if(data.latest_logs && data.latest_logs.length > 0) {
                data.latest_logs.forEach((log, index) => {
                    const isLatest = index === 0 ? 'latest' : '';
                    const badgeHtml = index === 0 ? `<span class="node-badge">${cfg.textLatest}</span>` : '';
                    
                    track.innerHTML += `
                        <div class="track-node ${isLatest}">
                            <div class="node-point"></div>
                            <div class="node-card">
                                ${badgeHtml}
                                <span class="node-time">${log.time}</span>
                                <span class="node-date">${log.date}</span>
                            </div>
                        </div>`;
                });
            } else {
                track.innerHTML = `
                    <div class="track-node latest">
                        <div class="node-point"></div>
                        <div class="node-card">
                            <span class="node-badge">${cfg.textLatest}</span>
                            <span class="node-time">${cfg.textFirst}</span>
                            <span class="node-date">${cfg.textJustNow}</span>
                        </div>
                    </div>`;
            }
            
            // If Success: Allow next scan automatically after 2.5s
            setTimeout(() => { isProcessing = false; }, 2500); 
            
        } else {
            // If Error: Hide timeline
            document.getElementById('logsSection').style.display = 'none';
        }

        // --- THE GUARD OVERLAY LOGIC (For Denials/Warnings) ---
        if (data.status_color === 'error' || data.status_color === 'warning') {
            document.getElementById('guardTitle').textContent = data.title;
            document.getElementById('guardMessage').textContent = data.message;
            guardOverlay.classList.add(data.status_color);
            guardOverlay.classList.add('show');
            
            const iconWrapper = document.getElementById('alertIconWrapper');
            if(data.status_color === 'error') {
                iconWrapper.innerHTML = `<svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><line x1="15" y1="9" x2="9" y2="15"/><line x1="9" y1="9" x2="15" y2="15"/></svg>`;
            } else {
                iconWrapper.innerHTML = `<svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"/><line x1="12" y1="9" x2="12" y2="13"/><line x1="12" y1="17" x2="12.01" y2="17"/></svg>`;
            }
            
            // CORE FIX: Apply Hard Lock preventing any new scans.
            isScannerLocked = true; 
            
            // Try to pause camera physically to save battery/processing
            if (scanner) {
                try { scanner.pause(true); } catch(e) {}
            }
        }
    }

    // Dismiss Guard to review ID
    dismissGuardBtn.addEventListener('click', () => {
        guardOverlay.classList.remove('show');
        if (scanner) {
            try { scanner.resume(); } catch(e) {}
        }
        
        // Unlock processing completely after a 1-second delay 
        // to prevent instantly re-scanning the same invalid QR code.
        setTimeout(() => { 
            isScannerLocked = false; 
            isProcessing = false; 
        }, 1000); 
    });

    openBtn.addEventListener('click', () => { overlay.classList.add('show'); startScanner(); });
    
    closeBtn.addEventListener('click', () => { 
        overlay.classList.remove('show'); 
        if(scanner && scanner.isScanning) {
            scanner.stop(); 
        }
        
        // Reset state completely
        document.getElementById('iconWait').style.display = 'block';
        document.getElementById('iconSuccess').style.display = 'none';
        document.getElementById('iconError').style.display = 'none';
        document.getElementById('statusBox').className = 'status-card';
        document.getElementById('resTitle').textContent = cfg.textReady;
        document.getElementById('resMsg').textContent = cfg.textAwaiting;
        guardOverlay.classList.remove('show');
        
        isProcessing = false; 
        isScannerLocked = false;
    });
});