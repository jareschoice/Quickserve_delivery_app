/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        quickserveGreen: "#1DB954",
        quickserveOrange: "#FF7A00",
        quickserveGold: "#FFD700",
        quickserveRed: "#E53935",
        quickserveCream: "#FFF8E1",
      },
    },
  },
  plugins: [],
}
