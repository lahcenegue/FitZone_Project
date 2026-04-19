'use strict';

document.addEventListener("DOMContentLoaded", function() {

    function getCsrfToken() {
        const tokenElement = document.querySelector('[name=csrfmiddlewaretoken]');
        return tokenElement ? tokenElement.value : '';
    }

    /* ====================================================================
       1. ADVANCED FILTERS PANEL TOGGLE
       ==================================================================== */
    const btnToggleAdvancedFilters = document.getElementById('btnToggleAdvancedFilters');
    const advancedFiltersPanel = document.getElementById('advancedFiltersPanel');

    if (btnToggleAdvancedFilters && advancedFiltersPanel) {
        btnToggleAdvancedFilters.addEventListener('click', () => {
            advancedFiltersPanel.classList.toggle('show');
            if(advancedFiltersPanel.classList.contains('show')) {
                btnToggleAdvancedFilters.style.backgroundColor = 'var(--color-bg)';
                btnToggleAdvancedFilters.style.borderColor = 'var(--color-primary)';
                btnToggleAdvancedFilters.style.color = 'var(--color-primary)';
            } else {
                btnToggleAdvancedFilters.style.backgroundColor = '';
                btnToggleAdvancedFilters.style.borderColor = '';
                btnToggleAdvancedFilters.style.color = '';
            }
        });
    }

    /* ====================================================================
       2. SMART FILTERS (Server-Side AJAX Engine via DOM Parsing)
       ==================================================================== */
    const searchInput = document.getElementById('ajaxSearch');
    const branchFilter = document.getElementById('ajaxBranch');
    const statusFilter = document.getElementById('ajaxStatus'); 
    const planFilter = document.getElementById('ajaxPlan');
    const expirationFilter = document.getElementById('ajaxExpiration');
    
    const listContainer = document.getElementById('subscribersListContainer');
    let debounceTimer;

    function fetchFilteredData() {
        if (!listContainer) return;

        const params = new URLSearchParams();
        if (searchInput && searchInput.value.trim()) params.append('search', searchInput.value.trim());
        if (branchFilter && branchFilter.value !== 'all') params.append('branch', branchFilter.value);
        if (statusFilter && statusFilter.value !== 'all') params.append('status', statusFilter.value);
        if (planFilter && planFilter.value !== 'all') params.append('plan', planFilter.value);
        if (expirationFilter && expirationFilter.value !== 'all') params.append('expiration', expirationFilter.value);

        listContainer.style.opacity = '0.4';
        listContainer.style.pointerEvents = 'none';

        fetch(`${window.location.pathname}?${params.toString()}`, {
            method: 'GET',
            headers: {
                'X-Requested-With': 'XMLHttpRequest',
                'Accept': 'text/html'
            }
        })
        .then(response => response.text())
        .then(html => {
            // CRITICAL FIX: Parse the returned HTML to extract ONLY the list wrapper.
            // This prevents duplicating the page header/stats if Django returns the full page.
            const parser = new DOMParser();
            const doc = parser.parseFromString(html, 'text/html');
            const newContent = doc.getElementById('subscribersListContainer');
            
            if (newContent) {
                listContainer.innerHTML = newContent.innerHTML;
            } else {
                // Fallback just in case
                listContainer.innerHTML = html;
            }
            
            listContainer.style.opacity = '1';
            listContainer.style.pointerEvents = 'auto';
            
            initAccordionToggles();
            initModalTriggers();
        })
        .catch(error => {
            console.error('AJAX Filter Error:', error);
            listContainer.style.opacity = '1';
            listContainer.style.pointerEvents = 'auto';
        });
    }

    if (searchInput) {
        searchInput.addEventListener('keyup', () => {
            clearTimeout(debounceTimer);
            debounceTimer = setTimeout(fetchFilteredData, 400); 
        });
    }
    
    const selects = [branchFilter, statusFilter, planFilter, expirationFilter];
    selects.forEach(select => {
        if (select) select.addEventListener('change', fetchFilteredData);
    });


    /* ====================================================================
       3. ACCORDION TOGGLE LOGIC
       ==================================================================== */
    window.toggleAccordion = function(headerElement) {
        const card = headerElement.closest('.member-accordion-card');
        if (card) {
            document.querySelectorAll('.member-accordion-card').forEach(c => {
                if (c !== card && c.classList.contains('open')) c.classList.remove('open');
            });
            card.classList.toggle('open');
        }
    };

    function initAccordionToggles() {
        const toggles = document.querySelectorAll('.btn-toggle-accordion');
        toggles.forEach(toggle => {
            const newToggle = toggle.cloneNode(true);
            toggle.parentNode.replaceChild(newToggle, toggle);
            newToggle.addEventListener('click', function(e) {
                if (e.target.closest('button') || e.target.closest('a')) return;
                window.toggleAccordion(this);
            });
        });
    }
    initAccordionToggles();


    /* ====================================================================
       4. MODAL MANAGEMENT (Block & Unblock Forms)
       ==================================================================== */
    const suspendModal = document.getElementById('suspendModal');
    const unblockModal = document.getElementById('unblockModal');
    const suspendForm = document.getElementById('suspendForm');
    const unblockForm = document.getElementById('unblockForm');
    
    function initModalTriggers() {
        document.querySelectorAll('.btn-open-suspend').forEach(btn => {
            const newBtn = btn.cloneNode(true);
            btn.parentNode.replaceChild(newBtn, btn);
            newBtn.addEventListener('click', function(e) {
                e.preventDefault(); e.stopPropagation();
                if (suspendForm) suspendForm.action = this.getAttribute('data-url');
                if (suspendModal) suspendModal.classList.add('show');
            });
        });

        document.querySelectorAll('.btn-open-unblock').forEach(btn => {
            const newBtn = btn.cloneNode(true);
            btn.parentNode.replaceChild(newBtn, btn);
            newBtn.addEventListener('click', function(e) {
                e.preventDefault(); e.stopPropagation();
                if (unblockForm) unblockForm.action = this.getAttribute('data-url');
                if (unblockModal) unblockModal.classList.add('show');
            });
        });
    }
    initModalTriggers();

    document.getElementById('btnCloseSuspend')?.addEventListener('click', () => {
        if(suspendModal) suspendModal.classList.remove('show');
    });
    document.getElementById('btnCloseUnblock')?.addEventListener('click', () => {
        if(unblockModal) unblockModal.classList.remove('show');
    });


    /* ====================================================================
       5. SECURE QR CODE SEARCH ENGINE
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
            if (html5QrcodeScanner) {
                try { html5QrcodeScanner.clear(); } catch(e) {}
            }
        });
    }

    function initializeSearchScanner() {
        if (typeof Html5QrcodeScanner === 'undefined') {
            alert("Scanner library missing.");
            return;
        }
        html5QrcodeScanner = new Html5QrcodeScanner("qr-reader-search", { fps: 10, qrbox: 250 });
        html5QrcodeScanner.render(async (decodedText) => {
            try { html5QrcodeScanner.clear(); } catch(e) {}
            qrSearchModal.classList.remove('show');
            
            try {
                const response = await fetch('/portal/api/gym/search-qr/', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json', 'X-CSRFToken': getCsrfToken() },
                    body: JSON.stringify({ token: decodedText })
                });
                const data = await response.json();
                
                if (data.status === 'success') {
                    window.location.href = data.redirect_url;
                } else {
                    alert(data.message);
                }
            } catch (error) {
                console.error('QR Search Error:', error);
                alert("Network error processing QR code.");
            }
        }, () => {}); 
    }
});

/* ====================================================================
   6. CSV EXPORT UTILITY
   ==================================================================== */
window.exportDataToCSV = function(tableId, filename) {
    let csv = [];
    const table = document.getElementById(tableId);
    if (!table) return;

    const rows = table.querySelectorAll("tr");
    for (let i = 0; i < rows.length; i++) {
        let row = [], cols = rows[i].querySelectorAll("td, th");
        for (let j = 0; j < cols.length; j++) {
            let data = cols[j].innerText.replace(/(\r\n|\n|\r)/gm, "").replace(/(\s\s)/gm, " ");
            data = data.replace(/"/g, '""');
            row.push('"' + data + '"');
        }
        csv.push(row.join(","));
    }

    const csvFile = new Blob(["\ufeff" + csv.join("\n")], { type: "text/csv;charset=utf-8;" });
    const downloadLink = document.createElement("a");
    downloadLink.download = filename;
    downloadLink.href = window.URL.createObjectURL(csvFile);
    downloadLink.style.display = "none";
    document.body.appendChild(downloadLink);
    downloadLink.click();
    document.body.removeChild(downloadLink);
};