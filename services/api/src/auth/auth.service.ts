import { Injectable, UnauthorizedException, BadRequestException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import * as bcrypt from 'bcryptjs';
import { PrismaService } from '../prisma/prisma.service';

// MVP: OTP dev-mode — код возвращаем в ответе (в проде заменить на SMS-провайдера).
// Антифрод: код живёт 5 мин, попыток ≤5, повторный запрос не чаще 1 раза в 60 сек (упрощённо).
@Injectable()
export class AuthService {
  constructor(private prisma: PrismaService, private jwt: JwtService) {}

  async requestOtp(phone: string) {
    const clean = phone.replace(/\D/g, '');
    if (clean.length < 10) throw new BadRequestException('bad phone');
    const recent = await this.prisma.otpCode.findFirst({
      where: { phone: clean },
      orderBy: { createdAt: 'desc' },
    });
    if (recent && Date.now() - recent.createdAt.getTime() < 60_000)
      throw new BadRequestException('wait 60s before retry');
    const code = String(Math.floor(1000 + Math.random() * 9000)); // 4 цифры для MVP
    await this.prisma.otpCode.create({
      data: { phone: clean, code, expiresAt: new Date(Date.now() + 5 * 60_000) },
    });
    return { sent: true, devCode: code }; // ⚠️ убрать devCode в проде!
  }

  async verifyOtp(phone: string, code: string) {
    const clean = phone.replace(/\D/g, '');
    const row = await this.prisma.otpCode.findFirst({
      where: { phone: clean },
      orderBy: { createdAt: 'desc' },
    });
    if (!row || row.expiresAt < new Date()) throw new UnauthorizedException('code expired');
    if (row.attempts >= 5) throw new UnauthorizedException('too many attempts');
    if (row.code !== code) {
      await this.prisma.otpCode.update({ where: { id: row.id }, data: { attempts: row.attempts + 1 } });
      throw new UnauthorizedException('wrong code');
    }
    let user = await this.prisma.user.findUnique({ where: { phone: clean } });
    if (!user) user = await this.prisma.user.create({ data: { phone: clean } });
    await this.prisma.otpCode.deleteMany({ where: { phone: clean } });
    const accessToken = await this.jwt.signAsync({ sub: user.id, phone: user.phone });
    return { accessToken, user: { id: user.id, phone: user.phone, guestQr: user.guestQr, stamps: user.stamps } };
  }
  // --- Персонал: вход по PIN в том же приложении (режим КДС) ---
  // PIN храним только как bcrypt-хэш. Роль кладём в JWT: role=staff.
  async staffLogin(login: string, pin: string) {
    const staff = await this.prisma.staff.findUnique({ where: { login } });
    if (!staff || !staff.isActive) throw new UnauthorizedException('bad credentials');
    const ok = await bcrypt.compare(pin, staff.pinHash);
    if (!ok) throw new UnauthorizedException('bad credentials');
    const accessToken = await this.jwt.signAsync({
      sub: staff.id, role: 'staff', staffRole: staff.role, shopId: staff.shopId,
    });
    return {
      accessToken,
      staff: { id: staff.id, login: staff.login, name: staff.name, role: staff.role, shopId: staff.shopId },
    };
  }

  async changeStaffPin(staffId: string, newPin: string) {
    if (!/^\d{4,8}$/.test(newPin)) throw new BadRequestException('pin must be 4-8 digits');
    const pinHash = await bcrypt.hash(newPin, 10);
    await this.prisma.staff.update({ where: { id: staffId }, data: { pinHash } });
    return { ok: true };
  }
}
