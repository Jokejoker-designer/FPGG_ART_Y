/// <reference types="vite/client" />

interface ImportMetaEnv {
  readonly VITE_GLASSBOX_TRANSPORT?: "fixture" | "http";
  readonly VITE_GLASSBOX_API?: string;
}

interface ImportMeta {
  readonly env: ImportMetaEnv;
}
