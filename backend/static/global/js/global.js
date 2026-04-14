/**
 * FitZone — Global JavaScript Utilities
 * Shared across all web pages (provider portal and dashboard).
 * No framework dependencies — vanilla JS only.
 */

'use strict';

/**
 * Read a cookie value by name.
 * Used for CSRF token retrieval.
 *
 * @param {string} name - Cookie name to look up.
 * @returns {string|null} Cookie value or null if not found.
 */
function getCookie(name) {
  const cookies = document.cookie.split(';');
  for (const cookie of cookies) {
    const [key, value] = cookie.trim().split('=');
    if (key === name) {
      return decodeURIComponent(value);
    }
  }
  return null;
}

/**
 * Get the CSRF token from cookies.
 * Required for all POST/PUT/DELETE requests.
 *
 * @returns {string|null} CSRF token value.
 */
function getCsrfToken() {
  return getCookie('csrftoken');
}

/**
 * Display a dismissible alert message on the page.
 *
 * @param {string} message - The message to display.
 * @param {'success'|'error'|'warning'|'info'} type - Alert type.
 * @param {string} containerId - ID of the container element to inject the alert into.
 */
function showAlert(message, type, containerId) {
  const container = document.getElementById(containerId);
  if (!container) return;

  const alertElement = document.createElement('div');
  alertElement.className = `alert alert--${type}`;
  alertElement.setAttribute('role', 'alert');
  alertElement.textContent = message;

  const dismissButton = document.createElement('button');
  dismissButton.className = 'alert__dismiss';
  dismissButton.setAttribute('aria-label', 'Dismiss');
  dismissButton.textContent = '×';
  dismissButton.addEventListener('click', () => alertElement.remove());

  alertElement.appendChild(dismissButton);
  container.prepend(alertElement);

  // Auto-dismiss after 5 seconds
  setTimeout(() => {
    if (alertElement.isConnected) {
      alertElement.remove();
    }
  }, 5000);
}

/**
 * Format a number as Saudi Riyal currency string.
 *
 * @param {number} amount - The numeric amount.
 * @returns {string} Formatted currency string.
 */
function formatCurrency(amount) {
  return new Intl.NumberFormat('ar-SA', {
    style: 'currency',
    currency: 'SAR',
  }).format(amount);
}

/**
 * Debounce a function call.
 * Prevents rapid repeated invocations (e.g. search input).
 *
 * @param {Function} fn - The function to debounce.
 * @param {number} delayMs - Delay in milliseconds.
 * @returns {Function} Debounced version of the function.
 */
function debounce(fn, delayMs) {
  let timeoutId = null;
  return function (...args) {
    clearTimeout(timeoutId);
    timeoutId = setTimeout(() => fn.apply(this, args), delayMs);
  };
}

/**
 * Make an authenticated fetch request with CSRF token included.
 *
 * @param {string} url - Request URL.
 * @param {RequestInit} options - Fetch options.
 * @returns {Promise<Response>} Fetch response promise.
 */
async function fetchWithCsrf(url, options = {}) {
  const headers = {
    'Content-Type': 'application/json',
    'X-CSRFToken': getCsrfToken(),
    ...options.headers,
  };
  return fetch(url, { ...options, headers });
}

/* ====================================================================
   GLOBAL LIGHTBOX ENGINE
   ==================================================================== */
window.openLightbox = function(imageSrc) {
  const modal = document.getElementById("lightboxModal");
  const img = document.getElementById("lightboxImg");
  if (modal && img) {
      img.src = imageSrc;
      modal.style.display = "flex";
  }
};

window.closeLightbox = function() {
  const modal = document.getElementById("lightboxModal");
  if (modal) {
      modal.style.display = "none";
  }
};

document.addEventListener('keydown', function(event) {
  if (event.key === "Escape") {
      closeLightbox();
  }
});