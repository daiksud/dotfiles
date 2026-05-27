import { useCallback, useEffect, useRef, useState } from 'react';
import useBaseUrl from '@docusaurus/useBaseUrl';
import styles from './styles.module.css';

export default function SearchBar(): JSX.Element {
  const [isOpen, setIsOpen] = useState(false);
  const containerRef = useRef<HTMLDivElement>(null);
  const pagefindRef = useRef<unknown>(null);
  const pagefindCssUrl = useBaseUrl('/pagefind/pagefind-ui.css');
  const pagefindJsUrl = useBaseUrl('/pagefind/pagefind-ui.js');
  const pagefindBundlePath = useBaseUrl('/pagefind/');

  const openModal = useCallback(() => setIsOpen(true), []);
  const closeModal = useCallback(() => setIsOpen(false), []);

  // Keyboard shortcut: Ctrl+K / ⌘+K
  useEffect(() => {
    const handler = (e: KeyboardEvent) => {
      if ((e.metaKey || e.ctrlKey) && e.key === 'k') {
        e.preventDefault();
        setIsOpen((prev) => !prev);
      }
      if (e.key === 'Escape') {
        setIsOpen(false);
      }
    };
    document.addEventListener('keydown', handler);
    return () => document.removeEventListener('keydown', handler);
  }, []);

  // Initialize Pagefind UI when modal opens
  useEffect(() => {
    if (!isOpen || !containerRef.current) return;
    if (pagefindRef.current) return;

    // Load Pagefind UI CSS
    if (!document.querySelector('link[href*="pagefind-ui.css"]')) {
      const link = document.createElement('link');
      link.rel = 'stylesheet';
      link.href = pagefindCssUrl;
      document.head.appendChild(link);
    }

    // Load Pagefind UI JS via script tag (avoid webpack resolution)
    const initPagefind = () => {
      // biome-ignore lint/suspicious/noExplicitAny: Pagefind UI is loaded at runtime
      const PagefindUI = (window as any).PagefindUI;
      if (!PagefindUI) {
        if (containerRef.current) {
          containerRef.current.innerHTML =
            '<p class="' +
            styles.notAvailable +
            '">検索インデックスが見つかりません。<br/><code>bun run docs:build</code> を実行してください。</p>';
        }
        return;
      }
      pagefindRef.current = new PagefindUI({
        element: containerRef.current,
        bundlePath: pagefindBundlePath,
        showSubResults: true,
        showImages: false,
        resetStyles: false,
        autofocus: true,
        translations: {
          placeholder: 'ドキュメントを検索...',
          zero_results: '「[SEARCH_TERM]」に一致する結果がありません',
          many_results: '[COUNT] 件の結果',
          one_result: '1 件の結果',
          searching: '検索中...',
          load_more: 'さらに表示',
        },
      });
    };

    // Check if already loaded
    // biome-ignore lint/suspicious/noExplicitAny: Pagefind UI is loaded at runtime
    if ((window as any).PagefindUI) {
      initPagefind();
    } else {
      const script = document.createElement('script');
      script.src = pagefindJsUrl;
      script.onload = initPagefind;
      script.onerror = () => {
        if (containerRef.current) {
          containerRef.current.innerHTML =
            '<p class="' +
            styles.notAvailable +
            '">検索インデックスが見つかりません。<br/><code>bun run docs:build</code> を実行してください。</p>';
        }
      };
      document.head.appendChild(script);
    }

    return () => {
      // Reset on close so we re-init fresh next time
      pagefindRef.current = null;
      if (containerRef.current) {
        containerRef.current.innerHTML = '';
      }
    };
  }, [isOpen, pagefindCssUrl, pagefindJsUrl, pagefindBundlePath]);

  // Close on backdrop click
  const handleBackdropClick = useCallback(
    (e: React.MouseEvent) => {
      if (e.target === e.currentTarget) {
        closeModal();
      }
    },
    [closeModal],
  );

  return (
    <>
      <button
        type="button"
        className={styles.searchButton}
        onClick={openModal}
        aria-label="サイト内検索"
      >
        <svg
          className={styles.searchIcon}
          width="20"
          height="20"
          viewBox="0 0 20 20"
          aria-hidden="true"
        >
          <path
            d="M14.386 14.386l4.088 4.088-4.088-4.088A7.533 7.533 0 1 1 3.733 3.733a7.533 7.533 0 0 1 10.653 10.653z"
            stroke="currentColor"
            fill="none"
            fillRule="evenodd"
            strokeLinecap="round"
            strokeLinejoin="round"
            strokeWidth="1.4"
          />
        </svg>
        <span className={styles.searchLabel}>検索</span>
        <kbd className={styles.searchKbd}>
          <span className={styles.searchKbdMeta}>⌘</span>K
        </kbd>
      </button>

      {isOpen && (
        <div // biome-ignore lint/a11y/useSemanticElements: modal backdrop
          className={styles.backdrop}
          onClick={handleBackdropClick}
          role="dialog"
          aria-modal="true"
          aria-label="サイト内検索"
        >
          <div className={styles.modal}>
            <div className={styles.modalHeader}>
              <span className={styles.modalTitle}>検索</span>
              <button
                type="button"
                className={styles.closeButton}
                onClick={closeModal}
                aria-label="閉じる"
              >
                <kbd>Esc</kbd>
              </button>
            </div>
            <div ref={containerRef} className={styles.searchContainer} />
          </div>
        </div>
      )}
    </>
  );
}
