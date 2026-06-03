import type { ReactNode } from "react";
import styles from "./styles.module.css";

type FeatureGridProps = {
  children: ReactNode;
};

export function FeatureGrid({ children }: FeatureGridProps) {
  return <div className={styles.grid}>{children}</div>;
}
