'use strict';

document.addEventListener("DOMContentLoaded", function() {

    /* ====================================================================
       1. SMART FILTERS (Search & Branch)
       ==================================================================== */
    const searchInput = document.getElementById('searchInput');
    const branchFilter = document.getElementById('branchFilter');
    const subscriberRows = document.querySelectorAll('.sub-row-card');

    function applyFilters() {
        if (!searchInput || !branchFilter) return;
        const term = searchInput.value.toLowerCase().trim();
        const branchId = branchFilter.value;

        subscriberRows.forEach(row => {
            const name = row.getAttribute('data-name') || '';
            const phone = row.getAttribute('data-phone') || '';
            const rowBranches = row.getAttribute('data-branch') ? row.getAttribute('data-branch').split(',') : [];

            const matchesSearch = name.includes(term) || phone.includes(term);
            const matchesBranch = branchId === 'all' || rowBranches.includes(branchId);

            row.style.display = (matchesSearch && matchesBranch) ? 'grid' : 'none';
        });
    }

    if (searchInput) searchInput.addEventListener('keyup', applyFilters);
    if (branchFilter) branchFilter.addEventListener('change', applyFilters);

    /* ====================================================================
       2. MODAL MANAGEMENT (Block & Unblock Forms)
       ==================================================================== */
    const suspendModal = document.getElementById('suspendModal');
    const unblockModal = document.getElementById('unblockModal');
    
    // Open Block Modal
    document.querySelectorAll('.btn-open-suspend').forEach(btn => {
        btn.addEventListener('click', function(e) {
            e.preventDefault(); e.stopPropagation();
            document.getElementById('suspendForm').action = this.getAttribute('data-url');
            if (suspendModal) suspendModal.classList.add('show');
        });
    });

    // Open Unblock Modal
    document.querySelectorAll('.btn-open-unblock').forEach(btn => {
        btn.addEventListener('click', function(e) {
            e.preventDefault(); e.stopPropagation();
            document.getElementById('unblockForm').action = this.getAttribute('data-url');
            if (unblockModal) unblockModal.classList.add('show');
        });
    });

    // Close Modals
    document.getElementById('btnCloseSuspend')?.addEventListener('click', () => suspendModal.classList.remove('show'));
    document.getElementById('btnCloseUnblock')?.addEventListener('click', () => unblockModal.classList.remove('show'));

    /* ====================================================================
       3. SECURE QR CODE SEARCH ENGINE (Quick Lookup)
       ==================================================================== */
    const qrSearchModal = document.getElementById('qrSearchModal');
    const btnOpenSearchScanner = document.getElementById('btnScanSearchQR');
    const btnCloseSearchScanner = document.getElementById('btnCloseSearchScanner');
    let html5QrcodeScanner = null;

    if (btnOpenSearchScanner && qrSearchModal) {
        btnOpenSearchScanner.addEventListener('click', () => {
            qrSearchModal.classList.add('show');
            initializeSearchScanner();
        });
    }

    if (btnCloseSearchScanner) {
        btnCloseSearchScanner.addEventListener('click', () => {
            qrSearchModal.classList.remove('show');
            if (html5QrcodeScanner) html5QrcodeScanner.clear();
        });
    }

    function initializeSearchScanner() {
        if (typeof Html5QrcodeScanner === 'undefined') {
            if (typeof showAlert === 'function') showAlert("Scanner library missing.", "error", "alert-container");
            return;
        }
        html5QrcodeScanner = new Html5QrcodeScanner("qr-reader-search", { fps: 10, qrbox: 250 });
        html5QrcodeScanner.render(async (decodedText) => {
            html5QrcodeScanner.clear();
            qrSearchModal.classList.remove('show');
            
            try {
                const response = await fetch('/portal/api/gym/search-qr/', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json', 'X-CSRFToken': getCsrfToken() },
                    body: JSON.stringify({ token: decodedText })
                });
                const data = await response.json();
                
                if (data.status === 'success') {
                    window.location.href = data.redirect_url; // Instant Redirect
                } else {
                    if (typeof showAlert === 'function') showAlert(data.message, 'error', 'alert-container');
                    else alert(data.message);
                }
            } catch (error) {
                console.error('QR Search Request Failed:', error);
            }
        }, () => {}); // Ignore empty frames
    }
});