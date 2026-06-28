import { GlobType, StartTemplateWithLambda } from '@atomicloud/cyan-sdk';

StartTemplateWithLambda(async (i, d) => {
  const availableLanguages = ['TypeScript', 'C#', 'Go'] as const;
  type Language = (typeof availableLanguages)[number];

  const languages = await i.checkbox(
    'Which languages are you using?',
    [...availableLanguages],
    'atomi/shared/languages',
  );
  const languageFiles = {
    TypeScript: 'typescript',
    'C#': 'csharp',
    Go: 'go',
  } satisfies Record<Language, string>;
  const isLanguage = (language: string): language is Language => language in languageFiles;
  const selectedLanguages = languages.filter(isLanguage);
  const vars = {
    useTypeScript: selectedLanguages.includes('TypeScript'),
    useCSharp: selectedLanguages.includes('C#'),
    useGo: selectedLanguages.includes('Go'),
  };
  const parser = {
    varSyntax: [['let___', '___']],
  };
  const config = { vars, parser };

  return {
    processors: [
      {
        name: 'cyan/default',
        files: [
          {
            root: 'templates',
            glob: '**/*.*',
            type: GlobType.Template,
            exclude: ['**/.DS_Store', 'docs/developer/standard/**/languages/*.md', 'claude/**/*'],
          },
        ],
        config,
      },
      ...selectedLanguages.map(language => {
        const file = languageFiles[language];
        return {
          name: 'cyan/default',
          files: [
            {
              root: 'templates',
              glob: `docs/developer/standard/**/languages/${file}.md`,
              type: GlobType.Template,
              exclude: [],
            },
          ],
          config,
        };
      }),
    ],
    plugins: [],
  };
});
