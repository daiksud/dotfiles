import type { ReactNode } from "react";
import styles from "./styles.module.css";

type TerminalProps = {
  title?: string;
  children: ReactNode;
};

export function Terminal({ title = "Terminal", children }: TerminalProps) {
  return (
    <div className={styles.terminal}>
      <div className={styles.header}>
        <div className={styles.dots}>
          <span className={styles.dot} data-color="red" />
          <span className={styles.dot} data-color="yellow" />
          <span className={styles.dot} data-color="green" />
        </div>
        <span className={styles.title}>{title}</span>
      </div>
      <div className={styles.body}>{children}</div>
    </div>
  );
}
Terminal.displayName = "Terminal";
