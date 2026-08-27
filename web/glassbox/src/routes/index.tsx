"use client";

import { createFileRoute } from "@tanstack/react-router";
import { Observatory } from "@/obs/observatory";

export const Route = createFileRoute("/")({ component: Home });

function Home() {
  return <Observatory />;
}
