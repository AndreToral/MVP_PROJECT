// supabaseClient.js

import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';

dotenv.config();

// Inicializa el cliente Supabase
const supabaseUrl = process.env.SUPABASE_URL;
const supabaseAnonKey = process.env.SUPABASE_ANON_KEY;

if (!supabaseUrl || !supabaseAnonKey) {
    console.error("❌ ERROR: Claves de Supabase no configuradas en .env");
    // En un entorno real, aquí deberías manejar el error
}

export const supabase = createClient(supabaseUrl, supabaseAnonKey);
console.log("✅ Cliente Supabase inicializado.");