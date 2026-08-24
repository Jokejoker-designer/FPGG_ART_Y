import { clsx, type ClassValue } from "clsx";
import { twMerge } from "tailwind-merge";

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

export function formatInt(n: number) {
  return new Intl.NumberFormat("en-US").format(n);
}

export function formatMs(n: number) {
  return `${n.toFixed(1)} ms`;
}
