
module.exports = {
  plguins: [
    require('postcss-import')(),
    require('tailwindcss')('./tailwind.config.js'),
    require('autoprefixer'),
  ],
};