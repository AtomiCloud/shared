import { GlobType, StartTemplateWithLambda } from '@atomicloud/cyan-sdk';

StartTemplateWithLambda(async (i, d) => {
  const vars = {};
  return {
    processors: [
      {
        name: 'cyan/default',
        files: [
          {
            root: 'templates',
            glob: '**/*.*',
            type: GlobType.Template,
            exclude: [],
          },
        ],
        config: {
          vars,
          parser: {
            varSyntax: [['let___', '___']],
          },
        },
      },
    ],
    plugins: [],
  };
});
