import { useSyncExternalStore } from "react";

/**
 * Whether the top-bar Tools button (tool definitions) is shown. Off by default:
 * the button only appears after the user enables it in Settings › General ›
 * Developer, so the dev-only Tools panel stays out of the way otherwise.
 *
 * Browser-local preference (localStorage), like the other UI toggles
 * (enter-send mode, files placement): privacy mode or quota errors fall back
 * to the default.
 */
export const DEV_TOOLS_ENABLED_STORAGE_KEY = "pi-web:dev-tools-enabled";
export const DEV_TOOLS_ENABLED_DEFAULT = false;

function readStored(): boolean {
  try {
    return window.localStorage.getItem(DEV_TOOLS_ENABLED_STORAGE_KEY) === "true";
  } catch {
    return DEV_TOOLS_ENABLED_DEFAULT;
  }
}

let enabled: boolean | null = null;
const listeners = new Set<() => void>();

function getSnapshot(): boolean {
  if (enabled === null) enabled = readStored();
  return enabled;
}

function subscribe(listener: () => void): () => void {
  listeners.add(listener);
  return () => { listeners.delete(listener); };
}

export function setDevToolsEnabled(next: boolean): void {
  enabled = next;
  try {
    window.localStorage.setItem(DEV_TOOLS_ENABLED_STORAGE_KEY, String(next));
  } catch {
    // Persistence is best-effort.
  }
  listeners.forEach((listener) => listener());
}

export function useDevToolsEnabled(): boolean {
  return useSyncExternalStore(subscribe, getSnapshot, () => DEV_TOOLS_ENABLED_DEFAULT);
}
