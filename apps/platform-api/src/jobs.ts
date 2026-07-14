import { Hono } from "hono";
import { rest } from "./supabase.js";

const LIST_COLUMNS =
  "id,job_posting_id,title,company_id,company_name,location,country_code,seniority_level,employment_type,salary_min,salary_max,salary_currency,salary_period,is_easy_apply,posted_at";

export const jobs = new Hono();

// GET /api/v1/jobs?q=&country=&seniority=&employment_type=&company_id=&page=&per_page=
jobs.get("/", async (c) => {
  const page = Math.max(1, Number(c.req.query("page") ?? 1) || 1);
  const perPage = Math.min(100, Math.max(1, Number(c.req.query("per_page") ?? 20) || 20));

  const params = new URLSearchParams({
    select: LIST_COLUMNS,
    order: "posted_at.desc",
    limit: String(perPage),
    offset: String((page - 1) * perPage),
  });

  const q = c.req.query("q");
  if (q) params.append("title", `ilike.*${q.replaceAll("*", "").replaceAll(",", "")}*`);
  const country = c.req.query("country");
  if (country) params.append("country_code", `eq.${country.toUpperCase()}`);
  const seniority = c.req.query("seniority");
  if (seniority) params.append("seniority_level", `eq.${seniority}`);
  const employmentType = c.req.query("employment_type");
  if (employmentType) params.append("employment_type", `eq.${employmentType}`);
  const companyId = c.req.query("company_id");
  if (companyId) params.append("company_id", `eq.${companyId}`);

  const { data, total } = await rest<unknown[]>(`jobs?${params}`, { count: true });
  return c.json({ jobs: data, page, per_page: perPage, total });
});

// GET /api/v1/jobs/:jobPostingId — full record incl. description
jobs.get("/:jobPostingId", async (c) => {
  const id = c.req.param("jobPostingId");
  const { data } = await rest<unknown[]>(`jobs?job_posting_id=eq.${encodeURIComponent(id)}&limit=1`);
  const job = data[0];
  if (!job) return c.json({ error: "not found" }, 404);
  return c.json({ job });
});
