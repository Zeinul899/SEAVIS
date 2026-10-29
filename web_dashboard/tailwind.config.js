/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        marine: {
          50: '#F0F9FF',
          100: '#E0F2FE',
          500: '#0284C7',
          700: '#0F4C81',
          900: '#0C355B',
        },
        seagrass: {
          50: '#ECFDF5',
          100: '#D1FAE5',
          500: '#10B981',
          600: '#059669',
          700: '#047857',
        }
      }
    },
  },
  plugins: [],
}
