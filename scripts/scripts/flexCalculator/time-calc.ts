import { readFile, writeFile } from "node:fs/promises";

type DurationUnit = "h" | "m" | "s";

const FIRST_MONTH = new Date(2026, 7, 1);
const PERSON_ID = "3428";
const TIME_DATABASE_URL = new URL("./time-calc-data.json", import.meta.url);

function parseDuration(durationText: string): Map<DurationUnit, number> {
  const durationMatch = /^(?:(\d+)h )?(?:(\d+)m )?(\d+)s$/.exec(durationText);
  if (!durationMatch) throw new Error("Invalid format");

  const [, hours, minutes, seconds] = durationMatch;
  const durationByUnit = new Map<DurationUnit, number>();

  if (hours !== undefined) durationByUnit.set("h", Number(hours));
  if (minutes !== undefined) durationByUnit.set("m", Number(minutes));
  durationByUnit.set("s", Number(seconds));

  return durationByUnit;
}

function durationToSeconds(durationByUnit: Map<DurationUnit, number>): number {
  const hours = durationByUnit.get("h") ?? 0;
  const minutes = durationByUnit.get("m") ?? 0;
  const seconds = durationByUnit.get("s") ?? 0;

  return hours * 3600 + minutes * 60 + seconds;
}

function formatDuration(totalSeconds: number): string {
  if (!Number.isSafeInteger(totalSeconds) || totalSeconds < 0) {
    throw new Error("Seconds must be a non-negative integer");
  }

  const hours = Math.floor(totalSeconds / 3600);
  const minutes = Math.floor((totalSeconds % 3600) / 60);
  const seconds = totalSeconds % 60;
  const formattedParts: string[] = [];

  if (hours > 0) formattedParts.push(`${hours}h`);
  if (minutes > 0) formattedParts.push(`${minutes}m`);
  formattedParts.push(`${seconds}s`);

  return formattedParts.join(" ");
}

function countWeekdaysInMonth(year: number, zeroBasedMonthIndex: number): number {
  const totalDaysInMonth = new Date(year, zeroBasedMonthIndex + 1, 0).getDate();
  let weekdayCount = Math.floor(totalDaysInMonth / 7) * 5;
  const trailingDays = totalDaysInMonth % 7;
  const firstTrailingDayOfWeek = new Date(year, zeroBasedMonthIndex, totalDaysInMonth - trailingDays + 1).getDay();

  for (let dayOffset = 0; dayOffset < trailingDays; dayOffset += 1) {
    const dayOfWeek = (firstTrailingDayOfWeek + dayOffset) % 7;
    if (dayOfWeek !== 0 && dayOfWeek !== 6) weekdayCount += 1;
  }

  return weekdayCount;
}

function countElapsedWeekdaysInCurrentMonth(countToday: boolean): number {
  const today = new Date();
  const elapsedCalendarDays = today.getDate() - (countToday ? 0 : 1);
  if (elapsedCalendarDays === 0) return 0;

  let elapsedWeekdayCount = Math.floor(elapsedCalendarDays / 7) * 5;
  const trailingElapsedDays = elapsedCalendarDays % 7;
  const firstTrailingDayOfWeek = new Date(today.getFullYear(), today.getMonth(), elapsedCalendarDays - trailingElapsedDays + 1).getDay();

  for (let dayOffset = 0; dayOffset < trailingElapsedDays; dayOffset += 1) {
    const dayOfWeek = (firstTrailingDayOfWeek + dayOffset) % 7;
    if (dayOfWeek !== 0 && dayOfWeek !== 6) elapsedWeekdayCount += 1;
  }

  return elapsedWeekdayCount;
}

function toMonthKey(date: Date): string {
  return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, "0")}`;
}

function parseWorkedSeconds(html: string, monthKey: string): number {
  const match = /Upparbetad tid:\s*(\d+)h(?:\s*(\d+)(?:min|m))?/i.exec(html);
  if (!match) throw new Error(`Could not find worked time for ${monthKey}; the cookie may have expired`);

  const [, hours, minutes = "0"] = match;
  return Number(hours) * 3600 + Number(minutes) * 60;
}

async function fetchWorkedSeconds(date: Date, cookie: string): Promise<[string, number]> {
  const monthKey = toMonthKey(date);
  const url = new URL("https://tid.surikat.net/time/month_overview.asp");
  url.search = new URLSearchParams({
    display: "table",
    month: `${monthKey}-01`,
    action: "show",
    person_id: PERSON_ID,
  }).toString();

  const response = await fetch(url, { headers: { Cookie: cookie } });
  if (!response.ok) throw new Error(`Failed to fetch ${monthKey}: ${response.status} ${response.statusText}`);

  return [monthKey, parseWorkedSeconds(await response.text(), monthKey)];
}

async function readTimeDatabase(): Promise<Map<string, number>> {
  try {
    const data = JSON.parse(await readFile(TIME_DATABASE_URL, "utf8")) as unknown;
    if (typeof data !== "object" || data === null || Array.isArray(data)) throw new Error("Database must be a JSON object");

    const entries = Object.entries(data);
    if (entries.some(([monthKey, seconds]) => !/^\d{4}-(0[1-9]|1[0-2])$/.test(monthKey) || !Number.isSafeInteger(seconds) || Number(seconds) < 0)) {
      throw new Error("Database contains invalid month data");
    }

    return new Map(entries as Array<[string, number]>);
  } catch (error) {
    if ((error as NodeJS.ErrnoException).code === "ENOENT") return new Map();
    throw new Error(`Failed to read time database: ${(error as Error).message}`);
  }
}

async function updateTimeDatabase(): Promise<Map<string, number>> {
  const cookie = process.env.TID_COOKIE;
  if (!cookie) throw new Error("TID_COOKIE is not set");

  const today = new Date();
  const currentMonthKey = toMonthKey(today);
  const workedSecondsByMonth = await readTimeDatabase();
  const monthsToFetch: Date[] = [];

  for (const date = new Date(FIRST_MONTH); date <= today; date.setMonth(date.getMonth() + 1)) {
    const monthKey = toMonthKey(date);
    if (monthKey === currentMonthKey || !workedSecondsByMonth.has(monthKey)) {
      monthsToFetch.push(new Date(date));
    }
  }

  const fetchedMonths = await Promise.all(monthsToFetch.map((month) => fetchWorkedSeconds(month, cookie)));
  for (const [monthKey, workedSeconds] of fetchedMonths) {
    workedSecondsByMonth.set(monthKey, workedSeconds);
  }

  await writeFile(TIME_DATABASE_URL, `${JSON.stringify(Object.fromEntries(workedSecondsByMonth), null, 2)}\n`, { mode: 0o600 });

  return workedSecondsByMonth;
}

function calculateFlexTimeSeconds(workedSecondsByMonth: Map<string, number>, countToday: boolean): number {
  const today = new Date();
  const currentMonthKey = toMonthKey(today);
  let flexTimeSeconds = 0;

  for (const [monthKey, workedSeconds] of workedSecondsByMonth) {
    const match = /^(\d{4})-(0[1-9]|1[0-2])$/.exec(monthKey);
    if (!match) throw new Error(`Invalid month key: ${monthKey}`);
    const year = Number(match[1]);
    const monthIndex = Number(match[2]) - 1;

    const weekdayCount = monthKey === currentMonthKey ? countElapsedWeekdaysInCurrentMonth(countToday) : countWeekdaysInMonth(year, monthIndex);
    const expectedSeconds = weekdayCount * 8 * 3600;
    flexTimeSeconds += workedSeconds - expectedSeconds;
  }

  return flexTimeSeconds;
}

const workedSecondsByMonth = await updateTimeDatabase();
const flexTimeSeconds = calculateFlexTimeSeconds(workedSecondsByMonth, false);
const sign = flexTimeSeconds < 0 ? "-" : "";
const formattedFlexTime = `${sign}${formatDuration(Math.abs(flexTimeSeconds))}`;
console.log({ flex: formattedFlexTime })
