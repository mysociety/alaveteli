/**
 * Combined Modal & Popup
 *
 * USAGE EXAMPLES:
 *
 * 1. Modal (triggered by button):
 *
 * <button class="modal-button">Open Video</button>
 * <div class="modal-content modal-hidden" aria-hidden="true">
 *    <button class="button modal-close">×</button>
 *    <div class="modal-container">
 *      <h2>Video Title</h2>
 *      <iframe src="https://www.youtube.com/embed/VIDEO_ID" frameborder="0" allowfullscreen></iframe>
 *    </div>
 * </div>
 *
 * 2. Auto-opening Popup:
 *
 * <div class="modal-content modal-hidden"
 *      aria-hidden="true"
 *      data-auto-open="true"
 *      data-open-delay="2000"
 *      data-click-outside-close="false">
 *   <button class="button modal-close">×</button>
 *   <div class="modal-container">
 *     <h2>Welcome!</h2>
 *     <p>This popup appears automatically after 2 seconds.</p>
 *   </div>
 * </div>
 *
 * DATA ATTRIBUTES:
 * - data-auto-open="true" - Makes it open automatically on page load
 * - data-open-delay="[milliseconds]" - Delay before auto-opening (optional)
 * - data-click-outside-close="false" - Prevents closing when clicking outside (optional)
 */

document.addEventListener('DOMContentLoaded', function() {
    // Store last focused element to return focus when modal/popup is closed
    let lastFocusedElement;

    const openedPopups = new Set();

    function init() {
        setupModalButtons();
        setupAutoPopups();
    }

    function setupModalButtons() {
        const modalButtons = document.querySelectorAll('.modal-button');

        modalButtons.forEach(button => {
            button.addEventListener('click', function(e) {
                e.preventDefault();
                const modalContent = this.nextElementSibling;
                if (modalContent && modalContent.classList.contains('modal-content')) {
                    openModal(modalContent);
                }
            });

            button.addEventListener('keydown', function(e) {
                if (e.key === 'Enter' || e.keyCode === 13) {
                    e.preventDefault();
                    const modalContent = this.nextElementSibling;
                    if (modalContent && modalContent.classList.contains('modal-content')) {
                        openModal(modalContent);
                    }
                }
            });
        });
    }

    function setupAutoPopups() {
        const autoPopups = document.querySelectorAll('.modal-content[data-auto-open="true"]');

        autoPopups.forEach(popup => {
            const popupId = popup.getAttribute('id') || Math.random().toString(36);
            // Check for delay
            const delay = parseInt(popup.dataset.openDelay) || 0;

            setTimeout(function() {
                if (!openedPopups.has(popupId)) {
                    openModal(popup);
                    openedPopups.add(popupId);
                }
            }, delay);
        });
    }

    function openModal(modalContent) {
        if (!modalContent) return;

        if (modalContent.getAttribute('aria-hidden') === 'false') return;
        // Store currently focused element
        lastFocusedElement = document.activeElement;

        modalContent.classList.remove('modal-hidden');
        modalContent.setAttribute('aria-hidden', 'false');

        // Create overlay
        const overlay = document.createElement('div');
        overlay.className = 'modal-overlay';
        document.body.appendChild(overlay);

        // Prevent page scrolling while modal is open
        document.body.style.overflow = 'hidden';

        setupFocusTrap(modalContent);

        // Focus the first focusable element
        const focusableElements = getFocusableElements(modalContent);
        if (focusableElements.length > 0) {
            setTimeout(function() {
                focusableElements[0].focus();
            }, 100);
        }

        // Wait for CSS transitions to complete
        setTimeout(function() {
            // First, try to initialize any pending carousels
            if (window.initPendingCarousels) {
                window.initPendingCarousels(modalContent);
            }

            // Then recalculate any already-initialized carousels
            if (window.recalculateCarousels) {
                window.recalculateCarousels(modalContent);
            }
        }, 50); // A delay to make sure the modal transition is done
    }

    function setupFocusTrap(modalContent) {
        // Add sentinel elements for focus trap
        const focusTrapStart = document.createElement('div');
        focusTrapStart.tabIndex = 0;
        focusTrapStart.className = 'focus-trap-start';
        focusTrapStart.style.cssText = 'position:absolute;width:1px;height:1px;padding:0;margin:-1px;overflow:hidden;clip:rect(0,0,0,0);white-space:nowrap;border:0;';

        const focusTrapEnd = document.createElement('div');
        focusTrapEnd.tabIndex = 0;
        focusTrapEnd.className = 'focus-trap-end';
        focusTrapEnd.style.cssText = 'position:absolute;width:1px;height:1px;padding:0;margin:-1px;overflow:hidden;clip:rect(0,0,0,0);white-space:nowrap;border:0;';

        modalContent.insertBefore(focusTrapStart, modalContent.firstChild);
        modalContent.appendChild(focusTrapEnd);

        focusTrapStart.addEventListener('focus', function() {
            const focusableElements = getFocusableElements(modalContent);
            if (focusableElements.length > 0) {
                focusableElements[focusableElements.length - 1].focus();
            }
        });

        focusTrapEnd.addEventListener('focus', function() {
            const focusableElements = getFocusableElements(modalContent);
            if (focusableElements.length > 0) {
                focusableElements[0].focus();
            }
        });
    }

    function getFocusableElements(container) {
        const selector = 'a[href], button:not([disabled]), input:not([disabled]), select:not([disabled]), textarea:not([disabled]), [tabindex]:not([tabindex="-1"]):not(.focus-trap-start):not(.focus-trap-end), iframe[src*="youtube"]';
        const elements = container.querySelectorAll(selector);

        // Filter for visible elements
        return Array.from(elements).filter(el => {
            return el.offsetWidth > 0 && el.offsetHeight > 0;
        });
    }

    // Close modal when clicking the close button
    document.addEventListener('click', function(e) {
        if (e.target.classList.contains('modal-close')) {
            closeModal();
        }

        // Close modal when clicking the overlay
        if (e.target.classList.contains('modal-overlay')) {
            const openModal = document.querySelector('.modal-content[aria-hidden="false"]');
            // Check if click-outside-close is disabled
            if (openModal && openModal.dataset.clickOutsideClose !== 'false') {
                closeModal();
            }
        }

        // Close modal when clicking outside the modal container
        if (e.target.classList.contains('modal-content')) {
            const modalContent = e.target;
            // Check if click-outside-close is disabled
            const clickOutsideClose = modalContent.dataset.clickOutsideClose !== 'false';

            // Only close if clicking directly on modal-content and click-outside is enabled
            if (clickOutsideClose) {
                closeModal();
            }
        }
    });

    document.addEventListener('keydown', function(e) {
        if ((e.key === 'Escape' || e.keyCode === 27)) {
            const openModal = document.querySelector('.modal-content[aria-hidden="false"]');

            if (openModal) {
                // Check if click-outside-close is disabled
                if (openModal.dataset.clickOutsideClose !== 'false') {
                    closeModal();
                }
            }
        }
    });

    function closeModal() {
        const openModal = document.querySelector('.modal-content[aria-hidden="false"]');

        if (openModal) {
            // Stop YouTube videos
            const iframes = openModal.querySelectorAll('iframe[src*="youtube"]');
            iframes.forEach(iframe => {
                iframe.contentWindow.postMessage('{"event":"command","func":"stopVideo","args":""}', '*');
            });

            // Remove sentinel elements
            const focusTraps = openModal.querySelectorAll('.focus-trap-start, .focus-trap-end');
            focusTraps.forEach(trap => trap.remove());

            openModal.classList.add('modal-hidden');
            openModal.setAttribute('aria-hidden', 'true');

            const overlay = document.querySelector('.modal-overlay');
            if (overlay) {
                overlay.remove();
            }

            document.body.style.overflow = '';

            // Return focus to the last focused element
            if (lastFocusedElement) {
                setTimeout(function() {
                    lastFocusedElement.focus();
                }, 10);
            }
        }
    }

    init();

    window.ModalPopup = {
        open: function(selector) {
            const element = document.querySelector(selector);
            if (element) {
                openModal(element);
            }
        },
        close: closeModal
    };
});
