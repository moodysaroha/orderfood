import { PrismaClient, SduiLayout, Role } from '@prisma/client';

export interface ISduiLayoutRepository {
  findByScreenAndRole(screenName: string, role: Role): Promise<SduiLayout | null>;
  findAll(): Promise<SduiLayout[]>;
  upsert(data: { screenName: string; role: Role; layoutJson: unknown; version?: number }): Promise<SduiLayout>;
}

export class SduiLayoutRepository implements ISduiLayoutRepository {
  constructor(private prisma: PrismaClient) {}

  async findByScreenAndRole(screenName: string, role: Role): Promise<SduiLayout | null> {
    return this.prisma.sduiLayout.findUnique({
      where: { screenName_role: { screenName, role } },
    });
  }

  async findAll(): Promise<SduiLayout[]> {
    return this.prisma.sduiLayout.findMany({ orderBy: { screenName: 'asc' } });
  }

  async upsert(data: { screenName: string; role: Role; layoutJson: unknown; version?: number }): Promise<SduiLayout> {
    return this.prisma.sduiLayout.upsert({
      where: { screenName_role: { screenName: data.screenName, role: data.role } },
      update: { layoutJson: data.layoutJson as any, version: data.version ? { increment: 1 } : undefined },
      create: { screenName: data.screenName, role: data.role, layoutJson: data.layoutJson as any },
    });
  }
}
