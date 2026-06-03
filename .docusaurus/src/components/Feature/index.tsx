import type { ReactNode } from "react";
import styles from "./styles.module.css";

type FeatureProps = {
  children: ReactNode;
};

export function Feature({ children }: FeatureProps) {
  return <div className={styles.card}>{children}</div>;
}
