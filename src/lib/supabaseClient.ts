import { createClient } from '@supabase/supabase-js';

// Public URL + anon key: designed to be exposed client-side. All real access
// control happens via Postgres Row Level Security (see the migrations) --
// this key alone grants nothing beyond what RLS policies explicitly allow.
const SUPABASE_URL = 'https://zcbocghfpgifpldbtaua.supabase.co';
const SUPABASE_ANON_KEY =
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpjYm9jZ2hmcGdpZnBsZGJ0YXVhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODM4NDE1MDAsImV4cCI6MjA5OTQxNzUwMH0.RWLF3TezsYefqs7d5FM6hypg2lr_E_p6dSXRYX0xgBc';

export const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

