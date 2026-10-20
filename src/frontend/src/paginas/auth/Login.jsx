import { useState } from "react";
import { Navigate, useNavigate } from "react-router-dom";
import { useAuth } from "../../auth/AuthContext";

export default function Login() {
  const { usuario, login } = useAuth();
  const nav = useNavigate();
  const [f, setF] = useState({ username: "", password: "" });
  const [err, setErr] = useState({});
  const [alerta, setAlerta] = useState("");
  const [cargando, setCargando] = useState(false);

  if (usuario) return <Navigate to="/" replace />;

  async function enviar(e) {
    e.preventDefault();
    const nuevo = {};
    if (!f.username.trim()) nuevo.username = "Escribe tu usuario.";
    if (!f.password) nuevo.password = "Escribe tu contraseña.";
    setErr(nuevo);
    setAlerta("");
    if (Object.keys(nuevo).length) return;
    setCargando(true);
    try {
      await login(f.username.trim(), f.password);
      nav("/");
    } catch (ex) {
      setAlerta(ex.message);
    } finally {
      setCargando(false);
    }
  }

  return (
    <div className="grid min-h-screen md:grid-cols-2">
      <aside className="flex flex-col justify-between bg-primary-dark p-8 text-white md:p-12">
        <div className="text-2xl font-extrabold tracking-tight">
          Steps<span className="text-accent">.</span>
        </div>
        <div>
          <h2 className="mb-3 max-w-[20ch] text-2xl font-extrabold leading-snug">
            Gestiona la atención de tu taller en un solo lugar
          </h2>
          <p className="max-w-[42ch] text-sm leading-relaxed text-white/70">
            Recepción, presupuestos, citas, inventario y pagos con QR, con
            acceso según tu rol.
          </p>
        </div>
        <small className="text-xs text-white/50">
          Steps · Gestión de taller mecánico
        </small>
      </aside>
      <div className="flex items-center justify-center p-6">
        <form onSubmit={enviar} className="tarjeta w-full max-w-md" noValidate>
          <div className="border-b border-borde p-5">
            <h1 className="text-lg font-bold">Iniciar sesión</h1>
            <p className="text-xs text-suave">
              Usa tu usuario y contraseña del taller.
            </p>
          </div>
          <div className="grid gap-4 p-6">
            {alerta && (
              <div
                role="alert"
                className="rounded-lg bg-red-100 p-3 text-sm font-semibold text-red-800"
              >
                {alerta}
              </div>
            )}
            <div>
              <label className="etiqueta" htmlFor="u">
                Usuario
              </label>
              <input
                id="u"
                className="campo"
                autoComplete="username"
                value={f.username}
                onChange={(e) => setF({ ...f, username: e.target.value })}
              />
              <p className="mt-1 min-h-4 text-xs text-peligro">
                {err.username}
              </p>
            </div>
            <div>
              <label className="etiqueta" htmlFor="p">
                Contraseña
              </label>
              <input
                id="p"
                type="password"
                className="campo"
                autoComplete="current-password"
                value={f.password}
                onChange={(e) => setF({ ...f, password: e.target.value })}
              />
              <p className="mt-1 min-h-4 text-xs text-peligro">
                {err.password}
              </p>
            </div>
            <button className="btn w-full" disabled={cargando}>
              {cargando ? "Entrando…" : "Entrar"}
            </button>
            <p className="rounded-lg border border-borde bg-slate-50 p-3 text-xs leading-relaxed text-suave">
              Tras 5 intentos fallidos la cuenta se bloquea 5 minutos.
            </p>
          </div>
        </form>
      </div>
    </div>
  );
}
