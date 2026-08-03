const getWeather = async () => {
  const weather = await fetch(
    "https://api.met.no/weatherapi/locationforecast/2.0/compact?lat=57.708870&lon=11.974560",
  );
  const json = await weather.json();
  const now = json.properties.timeseries[0].data;
  const temp = now.instant.details.air_temperature;
  const desc = now.next_1_hours.summary.symbol_code.split("_")[0];
  return { temp, desc };
};

getWeather()
  .then(({ temp, desc }) => console.log(`${temp}°C ${desc}`))
  .catch(() => console.log("N/A"));
