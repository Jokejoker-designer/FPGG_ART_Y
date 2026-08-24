import type { ErrorComponentProps } from "@tanstack/react-router";
import { StudioState } from "@/components/ui/studio-state";

export function AppErrorComponent({ error }: ErrorComponentProps) {
  return (
    <main className="flex min-h-screen flex-col items-center justify-center bg-bg px-6 py-10 text-fg">
      <StudioState kind="error">
        <p className="mt-2 max-w-md text-sm break-words text-muted">
          {error.message || "Thử tải lại studio."}
        </p>
      </StudioState>
    </main>
  );
}
