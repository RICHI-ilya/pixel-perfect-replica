import { createContext, useContext, useEffect, useMemo, useState, type ReactNode } from "react";
import type { Session } from "@supabase/supabase-js";
import { useQuery, useQueryClient } from "@tanstack/react-query";
import { supabase } from "@/integrations/supabase/client";

export type AppRole = "patient" | "doctor" | "admin";

export type Membership = {
  id: string;
  clinic_id: string;
  role: AppRole;
  clinic: { id: string; name: string; slug: string; timezone: string; allow_patient_reschedule: boolean };
};

type AuthValue = {
  session: Session | null;
  loading: boolean;
  memberships: Membership[];
  membershipsLoading: boolean;
  active: Membership | null;
  setActiveId: (id: string) => void;
  signOut: () => Promise<void>;
  refresh: () => void;
};

const AuthContext = createContext<AuthValue | null>(null);
const STORAGE_KEY = "clinicore.active-membership";

export function AuthProvider({ children }: { children: ReactNode }) {
  const [session, setSession] = useState<Session | null>(null);
  const [loading, setLoading] = useState(true);
  const [activeId, setActiveIdState] = useState<string | null>(null);
  const queryClient = useQueryClient();

  useEffect(() => {
    const { data: sub } = supabase.auth.onAuthStateChange((_event, next) => {
      setSession(next);
      setLoading(false);
      queryClient.invalidateQueries();
    });
    supabase.auth.getSession().then(({ data }) => {
      setSession(data.session);
      setLoading(false);
    });
    setActiveIdState(window.localStorage.getItem(STORAGE_KEY));
    return () => sub.subscription.unsubscribe();
  }, [queryClient]);

  const userId = session?.user?.id ?? null;

  const membershipsQuery = useQuery({
    queryKey: ["memberships", userId],
    enabled: !!userId,
    queryFn: async (): Promise<Membership[]> => {
      const { data, error } = await supabase
        .from("clinic_members")
        .select("id, clinic_id, role, clinic:clinics(id, name, slug, timezone, allow_patient_reschedule)")
        .order("created_at", { ascending: true });
      if (error) throw error;
      return (data ?? []) as unknown as Membership[];
    },
  });

  const memberships = membershipsQuery.data ?? [];

  const setActiveId = (id: string) => {
    window.localStorage.setItem(STORAGE_KEY, id);
    setActiveIdState(id);
  };

  const active = useMemo(() => {
    if (memberships.length === 0) return null;
    return memberships.find((m) => m.id === activeId) ?? memberships[0];
  }, [memberships, activeId]);

  const value: AuthValue = {
    session,
    loading,
    memberships,
    membershipsLoading: !!userId && membershipsQuery.isLoading,
    active,
    setActiveId,
    signOut: async () => {
      await supabase.auth.signOut();
      window.localStorage.removeItem(STORAGE_KEY);
      queryClient.clear();
    },
    refresh: () => {
      void membershipsQuery.refetch();
    },
  };

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error("useAuth must be used inside AuthProvider");
  return ctx;
}
