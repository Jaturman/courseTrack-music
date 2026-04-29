export default {
	async fetch(request: Request, env: any, ctx: ExecutionContext): Promise<Response> {
		const url = new URL(request.url);

		if (url.pathname === "/submit" && request.method === "POST") {
			return handleSubmit(request, env);
		}

		if (url.pathname === "/leaderboard/summary" && request.method === "GET") {
			return handleLeaderboardSummary(url, env);
		}

		if (url.pathname === "/leaderboard/period" && request.method === "GET") {
			return handleLeaderboardPeriod(env);
		}

		if (url.pathname === "/leaderboard/top50" && request.method === "GET") {
			return handleLeaderboardTop50(url, env);
		}

		if (url.pathname === "/health") {
			return new Response("OK", { status: 200 });
		}

		return new Response("Not Found", { status: 404 });
	},
};

async function handleSubmit(request: Request, env: any): Promise<Response> {
	const expectedApiKey = env?.X_API_KEY ?? "";
	const providedApiKey = request.headers.get("x-api-key") ?? "";

	// Seguridad mínima: si no coincide el x-api-key, denegamos.
	// Para dev local usaremos el valor en wrangler.jsonc.
	if (!expectedApiKey || providedApiKey !== expectedApiKey) {
		return new Response("Unauthorized", { status: 401 });
	}

	let payload: any;
	try {
		payload = await request.json();
	} catch {
		return new Response("Bad Request: invalid JSON", { status: 400 });
	}

	const nameRaw = payload?.name;
	const valueRaw = payload?.value;

	if (typeof nameRaw !== "string") return new Response("Bad Request: name", { status: 400 });
	if (nameRaw.length <= 0 || nameRaw.length > 8) {
		return new Response("Bad Request: name length", { status: 400 });
	}

	const valueNum = Number(valueRaw);
	if (!Number.isFinite(valueNum)) return new Response("Bad Request: value", { status: 400 });

	// Guardamos valores como enteros (mg * 1), redondeando.
	const value = Math.round(valueNum);
	if (value < 0) return new Response("Bad Request: value", { status: 400 });

	// UTC keys y timestamp para desempates "primero en llegar".
	const now = new Date();
	const dayKey = now.toISOString().slice(0, 10); // YYYY-MM-DD
	const monthKey = now.toISOString().slice(0, 7); // YYYY-MM
	const yearKey = String(now.getUTCFullYear()); // YYYY
	const ts = now.getTime(); // ms UTC

	// D1 guarda todo en SQLite. Usamos UPSERT con actualización SOLO si el valor es estrictamente mayor.
	// Si empata, dejamos el registro anterior (primer en llegar).
	const stmtUser = env.DB.prepare(
		`
      INSERT INTO users (name, best_value, best_ts)
      VALUES (?, ?, ?)
      ON CONFLICT(name) DO UPDATE SET
        best_value = CASE
          WHEN excluded.best_value > users.best_value THEN excluded.best_value
          ELSE users.best_value
        END,
        best_ts = CASE
          WHEN excluded.best_value > users.best_value THEN excluded.best_ts
          WHEN excluded.best_value = users.best_value AND excluded.best_ts < users.best_ts THEN excluded.best_ts
          ELSE users.best_ts
        END
    `
	).bind(nameRaw, value, ts);

	const stmtDay = env.DB.prepare(
		`
      INSERT INTO winners_day (day_key, name, value, ts)
      VALUES (?, ?, ?, ?)
      ON CONFLICT(day_key) DO UPDATE SET
        name = CASE
          WHEN excluded.value > winners_day.value THEN excluded.name
          WHEN excluded.value = winners_day.value AND excluded.ts < winners_day.ts THEN excluded.name
          ELSE winners_day.name
        END,
        value = CASE
          WHEN excluded.value > winners_day.value THEN excluded.value
          ELSE winners_day.value
        END,
        ts = CASE
          WHEN excluded.value > winners_day.value THEN excluded.ts
          WHEN excluded.value = winners_day.value AND excluded.ts < winners_day.ts THEN excluded.ts
          ELSE winners_day.ts
        END
    `
	).bind(dayKey, nameRaw, value, ts);

	const stmtMonth = env.DB.prepare(
		`
      INSERT INTO winners_month (month_key, name, value, ts)
      VALUES (?, ?, ?, ?)
      ON CONFLICT(month_key) DO UPDATE SET
        name = CASE
          WHEN excluded.value > winners_month.value THEN excluded.name
          WHEN excluded.value = winners_month.value AND excluded.ts < winners_month.ts THEN excluded.name
          ELSE winners_month.name
        END,
        value = CASE
          WHEN excluded.value > winners_month.value THEN excluded.value
          ELSE winners_month.value
        END,
        ts = CASE
          WHEN excluded.value > winners_month.value THEN excluded.ts
          WHEN excluded.value = winners_month.value AND excluded.ts < winners_month.ts THEN excluded.ts
          ELSE winners_month.ts
        END
    `
	).bind(monthKey, nameRaw, value, ts);

	const stmtYear = env.DB.prepare(
		`
      INSERT INTO winners_year (year_key, name, value, ts)
      VALUES (?, ?, ?, ?)
      ON CONFLICT(year_key) DO UPDATE SET
        name = CASE
          WHEN excluded.value > winners_year.value THEN excluded.name
          WHEN excluded.value = winners_year.value AND excluded.ts < winners_year.ts THEN excluded.name
          ELSE winners_year.name
        END,
        value = CASE
          WHEN excluded.value > winners_year.value THEN excluded.value
          ELSE winners_year.value
        END,
        ts = CASE
          WHEN excluded.value > winners_year.value THEN excluded.ts
          WHEN excluded.value = winners_year.value AND excluded.ts < winners_year.ts THEN excluded.ts
          ELSE winners_year.ts
        END
    `
	).bind(yearKey, nameRaw, value, ts);

	await env.DB.batch([stmtUser, stmtDay, stmtMonth, stmtYear]);

	return new Response(JSON.stringify({ ok: true }), {
		status: 200,
		headers: { "Content-Type": "application/json" },
	});
}

function json(data: any, status = 200): Response {
	return new Response(JSON.stringify(data), {
		status,
		headers: { "Content-Type": "application/json" },
	});
}

function utcKeys(now: Date) {
	const dayKey = now.toISOString().slice(0, 10); // YYYY-MM-DD
	const monthKey = now.toISOString().slice(0, 7); // YYYY-MM
	const yearKey = String(now.getUTCFullYear()); // YYYY
	return { dayKey, monthKey, yearKey };
}

async function handleLeaderboardPeriod(env: any): Promise<Response> {
	const now = new Date();
	const { dayKey, monthKey, yearKey } = utcKeys(now);

	const winnersDay = await env.DB.prepare(
		`SELECT name, value, ts FROM winners_day WHERE day_key = ?`
	)
		.bind(dayKey)
		.first();

	const winnersMonth = await env.DB.prepare(
		`SELECT name, value, ts FROM winners_month WHERE month_key = ?`
	)
		.bind(monthKey)
		.first();

	const winnersYear = await env.DB.prepare(
		`SELECT name, value, ts FROM winners_year WHERE year_key = ?`
	)
		.bind(yearKey)
		.first();

	return json({
		day: winnersDay ?? null,
		month: winnersMonth ?? null,
		year: winnersYear ?? null,
	});
}

async function handleLeaderboardSummary(url: URL, env: any): Promise<Response> {
	const name = url.searchParams.get("name") ?? "";
	const now = new Date();
	const { dayKey, monthKey, yearKey } = utcKeys(now);

	// Ganadores actuales del periodo (UTC)
	const winnersDay = await env.DB.prepare(
		`SELECT name, value, ts FROM winners_day WHERE day_key = ?`
	)
		.bind(dayKey)
		.first();
	const winnersMonth = await env.DB.prepare(
		`SELECT name, value, ts FROM winners_month WHERE month_key = ?`
	)
		.bind(monthKey)
		.first();
	const winnersYear = await env.DB.prepare(
		`SELECT name, value, ts FROM winners_year WHERE year_key = ?`
	)
		.bind(yearKey)
		.first();

	if (!name) {
		return json({
			me: null,
			period: {
				day: winnersDay ?? null,
				month: winnersMonth ?? null,
				year: winnersYear ?? null,
			},
		});
	}

	// Mejor marca del usuario + puesto global (all-time) con tie-break por best_ts (primero en llegar).
	const meRow = await env.DB.prepare(
		`
    SELECT
      u.name,
      u.best_value,
      u.best_ts,
      (
        1
        + (SELECT COUNT(*) FROM users u2 WHERE u2.best_value > u.best_value)
        + (SELECT COUNT(*) FROM users u2 WHERE u2.best_value = u.best_value AND u2.best_ts < u.best_ts)
      ) AS rank_global
    FROM users u
    WHERE u.name = ?
  `
	)
		.bind(name)
		.first();

	const me = meRow
		? {
				name: meRow.name,
				bestValue: meRow.best_value,
				rankGlobal: meRow.rank_global,
		  }
		: null;

	return json({
		me,
		period: {
			day: winnersDay ?? null,
			month: winnersMonth ?? null,
			year: winnersYear ?? null,
		},
	});
}

async function handleLeaderboardTop50(url: URL, env: any): Promise<Response> {
	const offset = Math.max(0, Number(url.searchParams.get("offset") ?? 0));
	const limit = Math.max(1, Math.min(10, Number(url.searchParams.get("limit") ?? 10)));

	const res = await env.DB.prepare(
		`
    SELECT name, best_value AS value
    FROM users
    ORDER BY best_value DESC, best_ts ASC
    LIMIT ? OFFSET ?
  `
	)
		.bind(limit, offset)
		.all();

	// En D1, `all()` suele devolver { results: [...] }.
	const rows = (res && (res as any).results) ? (res as any).results : res;

	return json({
		entries: rows.map((r: any) => ({
			name: r.name,
			value: r.value,
		})),
	});
}
