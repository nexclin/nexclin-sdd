"use client";

import { useEffect, useState } from "react";
import { createClient } from "@/lib/supabase/client";

/**
 * Hook client-side para UI condicional. A autorização REAL é do banco
 * (RLS + is_superadmin) e do guard server-side; este hook é só conveniência
 * de renderização. Consome a função is_superadmin do Postgres.
 */
export function useSuperAdmin() {
  const [isSuperAdmin, setIsSuperAdmin] = useState(false);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    let active = true;
    const supabase = createClient();

    (async () => {
      const {
        data: { user },
      } = await supabase.auth.getUser();
      if (!user) {
        if (active) {
          setIsSuperAdmin(false);
          setIsLoading(false);
        }
        return;
      }
      const { data, error } = await supabase.rpc("is_superadmin", {
        _user_id: user.id,
      });
      if (active) {
        setIsSuperAdmin(!error && data === true);
        setIsLoading(false);
      }
    })();

    return () => {
      active = false;
    };
  }, []);

  return { isSuperAdmin, isLoading };
}
