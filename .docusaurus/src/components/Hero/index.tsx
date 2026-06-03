import { Children, isValidElement, type ReactNode } from "react";
import styles from "./styles.module.css";

type HeroProps = {
  children: ReactNode;
};

function getDisplayName(child: ReactNode): string | undefined {
  if (!isValidElement(child)) return undefined;
  const type = child.type;
  if (typeof type === "function" || typeof type === "object") {
    return (type as { displayName?: string }).displayName;
  }
  return undefined;
}

export function Hero({ children }: HeroProps) {
  const leftContent: ReactNode[] = [];
  const rightContent: ReactNode[] = [];

  Children.forEach(children, (child) => {
    const name = getDisplayName(child);
    if (name === "HeroRight") {
      rightContent.push(child);
    } else if (name === "HeroLeft") {
      leftContent.push(child);
    } else {
      leftContent.push(child);
    }
  });

  return (
    <section className={styles.hero}>
      <div className={`container ${styles.layout}`}>
        <div className={styles.left}>{leftContent}</div>
        {rightContent.length > 0 && (
          <div className={styles.right}>{rightContent}</div>
        )}
      </div>
    </section>
  );
}

export function HeroLeft({ children }: { children: ReactNode }) {
  return <>{children}</>;
}
HeroLeft.displayName = "HeroLeft";

export function HeroRight({ children }: { children: ReactNode }) {
  return <>{children}</>;
}
HeroRight.displayName = "HeroRight";
