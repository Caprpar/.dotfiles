// Nerd Font "Weather Icons" glyphs (requires a Nerd Font, e.g. JetBrainsMono Nerd Font)
const SYMBOLS = {
  clearsky: "", // nf-weather-day_sunny
  fair: "", // nf-weather-day_cloudy
  partlycloudy: "", // nf-weather-day_cloudy
  cloudy: "", // nf-weather-cloudy
  fog: "", // nf-weather-fog
  rain: "", // nf-weather-rain
  lightrain: "", // nf-weather-day_showers
  heavyrain: "", // nf-weather-rain
  rainshowers: "", // nf-weather-showers
  lightrainshowers: "", // nf-weather-day_showers
  heavyrainshowers: "", // nf-weather-showers
  rainandthunder: "", // nf-weather-thunderstorm
  heavyrainandthunder: "", // nf-weather-thunderstorm
  lightrainandthunder: "", // nf-weather-day_lightning
  rainshowersandthunder: "", // nf-weather-thunderstorm
  lightrainshowersandthunder: "", // nf-weather-day_lightning
  heavyrainshowersandthunder: "", // nf-weather-thunderstorm
  sleet: "", // nf-weather-sleet
  lightsleet: "", // nf-weather-day_sleet
  heavysleet: "", // nf-weather-sleet
  sleetshowers: "", // nf-weather-sleet
  lightsleetshowers: "", // nf-weather-day_sleet
  heavysleetshowers: "", // nf-weather-sleet
  sleetandthunder: "", // nf-weather-thunderstorm
  snow: "", // nf-weather-snow
  lightsnow: "", // nf-weather-day_snow
  heavysnow: "", // nf-weather-snow
  snowshowers: "", // nf-weather-day_snow
  lightsnowshowers: "", // nf-weather-day_snow
  heavysnowshowers: "", // nf-weather-snow_wind
  snowandthunder: "", // nf-weather-thunderstorm
};

const getSymbol = (symbolCode) => {
  const key = symbolCode.split("_")[0];
  return SYMBOLS[key] ?? "?";
};

const getWeather = async () => {
  const weather = await fetch(
    "https://api.met.no/weatherapi/locationforecast/2.0/compact?lat=57.708870&lon=11.974560",
  );
  const json = await weather.json();
  const now = json.properties.timeseries[0].data;
  const temp = now.instant.details.air_temperature;
  const symbol = getSymbol(now.next_1_hours.summary.symbol_code);
  return { temp, symbol };
};

getWeather()
  .then(({ temp, symbol }) => console.log(`${temp}°C ${symbol}`))
  .catch(() => console.log("N/A"));
