import path from 'path';

export default {
  earlyAccess: true,
  schema: path.join(__dirname, 'prisma', 'schema.prisma'),
  seed: {
    command: 'npx ts-node prisma/seed.ts',
  },
};
