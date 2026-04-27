/**
 * FitZone QR Scanner Logic
 * Separated for DRY compliance. Relies on window.FIT_ZONE_QR_CONFIG for translations/URLs.
 * Implements Smart Branch Persistence via localStorage.
 */

'use strict';

document.addEventListener("DOMContentLoaded", function() {
    let scanner = null;
    let isProcessing = false; 
    let isScannerLocked = false; 
    const cfg = window.FIT_ZONE_QR_CONFIG; 
    const STORAGE_KEY = 'fitzone_active_scanner_branch_id';

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
    const branchSelector = document.getElementById('activeBranchSelector');

    if (branchSelector) {
        const savedBranch = localStorage.getItem(STORAGE_KEY);
        if (savedBranch) {
            const exists = Array.from(branchSelector.options).some(opt => opt.value === savedBranch);
            if (exists) {
                branchSelector.value = savedBranch;
            }
        } else {
            localStorage.setItem(STORAGE_KEY, branchSelector.value);
        }

        branchSelector.addEventListener('change', function() {
            localStorage.setItem(STORAGE_KEY, this.value);
        });
    }

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
        isScannerLocked = false;
        
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
        if (isScannerLocked || isProcessing) return; 
        
        let cleanText = decodedText.trim();
        if (!cleanText.startsWith("FZ-SUB-") && !cleanText.startsWith("FZ-ROAM-")) return; 

        isProcessing = true;
        
        const activeBranchId = branchSelector ? parseInt(branchSelector.value) : null;

        fetch(cfg.apiUrl, {
            method: "POST",
            headers: { "Content-Type": "application/json", "X-CSRFToken": cfg.csrfToken },
            body: JSON.stringify({ 
                qr_code_data: cleanText, 
                branch_id: activeBranchId 
            })
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

        const visitBadge = document.getElementById('resVisitTypeBadge');
        if (visitBadge) {
            if (data.is_roaming) {
                visitBadge.textContent = "ROAMING";
                visitBadge.className = "node-badge badge-roaming";
                visitBadge.style.display = "inline-block";
            } else {
                visitBadge.textContent = "REGULAR";
                visitBadge.className = "node-badge badge-regular";
                visitBadge.style.display = "inline-block";
            }
        }

        const statusBox = document.getElementById('statusBox');
        statusBox.className = `status-card ${data.status_color}`;
        document.getElementById('resTitle').textContent = data.title;
        document.getElementById('resMsg').textContent = data.message;
        document.getElementById('iconWait').style.display = 'none';
        document.getElementById('iconSuccess').style.display = data.status_color === 'success' ? 'block' : 'none';
        document.getElementById('iconError').style.display = (data.status_color === 'error' || data.status_color === 'warning') ? 'block' : 'none';

        // ALWAYS UPDATE CHART (Even on error)
        const left = data.days_left || 0;
        const total = data.total_days || 1;
        
        let pct = 0;
        if (data.is_roaming) {
            pct = (data.status_color === 'error' && left === 0) ? 0 : 100;
        } else {
            pct = Math.max(0, Math.min(100, (left / total) * 100));
        }
        
        document.getElementById('resDaysLeft').textContent = data.is_roaming ? (left > 0 ? "1" : "0") : left;
        document.getElementById('resChartLbl').textContent = data.is_roaming ? "USE" : "Days Left";
        
        const chart = document.getElementById('resChart');
        chart.style.setProperty('--progress', `${pct}%`);
        
        let ringColor = "primary";
        if (data.is_roaming) ringColor = "purple";
        else if (data.status_color === 'warning') ringColor = "warning";
        else if (data.status_color === 'error') ringColor = "error";
        
        chart.style.background = `conic-gradient(var(--color-${ringColor}) var(--progress), var(--color-bg) 0deg)`;

        // ALWAYS RENDER TIMELINE (Even on error)
        document.getElementById('logsSection').style.display = 'flex';
        document.getElementById('resCapacity').textContent = data.current_capacity || "0";
        
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
                            <span class="node-branch" style="display:block; font-size:10px; font-weight:700; color:var(--color-primary); margin-top:4px;">${log.branch_name}</span>
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
                        <span class="node-branch" style="display:block; font-size:10px; font-weight:700; color:var(--color-primary); margin-top:4px;">-</span>
                    </div>
                </div>`;
        }

        if (data.status_color !== 'error') {
            setTimeout(() => { isProcessing = false; }, 2500); 
        } else {
            document.getElementById('guardTitle').textContent = data.title;
            document.getElementById('guardMessage').textContent = data.message;
            guardOverlay.classList.add(data.status_color);
            guardOverlay.classList.add('show');
            
            const iconWrapper = document.getElementById('alertIconWrapper');
            iconWrapper.innerHTML = `<svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="10"/><line x1="15" y1="9" x2="9" y2="15"/><line x1="9" y1="9" x2="15" y2="15"/></svg>`;
            
            if (data.redirect_url) {
                dismissGuardBtn.setAttribute('data-url', data.redirect_url);
            }

            isScannerLocked = true; 
            
            if (scanner) {
                try { scanner.pause(true); } catch(e) {}
            }
        }
    }

    dismissGuardBtn.addEventListener('click', function() {
        const url = this.getAttribute('data-url');
        if (url) {
            window.location.href = url;
            return;
        }

        guardOverlay.classList.remove('show');
        if (scanner) {
            try { scanner.resume(); } catch(e) {}
        }
        
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