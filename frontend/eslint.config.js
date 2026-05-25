import js from '@eslint/js';
import ts from 'typescript-eslint';
import svelte from 'eslint-plugin-svelte';
import globals from 'globals';

export default [
  js.configs.recommended,
  ...ts.configs.recommended,
  ...svelte.configs['flat/recommended'],
  {
    languageOptions: {
      globals: { ...globals.browser, ...globals.node },
    },
  },
  {
    files: ['**/*.svelte'],
    languageOptions: {
      parserOptions: { parser: ts.parser },
    },
  },
  {
    files: ['**/*.svelte.ts'],
    languageOptions: {
      parser: ts.parser,
    },
  },
  {
    rules: {
      // this project has no custom routing hooks, so resolve() is not needed
      'svelte/no-navigation-without-resolve': 'off',
    },
  },
  {
    ignores: ['build/', '.svelte-kit/', 'dist/', '.vercel/'],
  },
];
