import { Body, Controller, Post, UseGuards, Req } from '@nestjs/common';
import { IsString, MinLength } from 'class-validator';
import { AuthService } from './auth.service';
import { JwtGuard } from './jwt.guard';
class PhoneDto { @IsString() @MinLength(6) phone!: string; }
class VerifyDto { @IsString() phone!: string; @IsString() @MinLength(4) code!: string; }
class StaffLoginDto { @IsString() login!: string; @IsString() @MinLength(4) pin!: string; }
class ChangePinDto { @IsString() @MinLength(4) newPin!: string; }
@Controller('auth')
export class AuthController {
  constructor(private auth: AuthService) {}
  @Post('otp/request') request(@Body() b: PhoneDto) { return this.auth.requestOtp(b.phone); }
  @Post('otp/verify') verify(@Body() b: VerifyDto) { return this.auth.verifyOtp(b.phone, b.code); }
  // Вход персонала по PIN (режим КДС в том же приложении)
  @Post('staff/login') staffLogin(@Body() b: StaffLoginDto) { return this.auth.staffLogin(b.login, b.pin); }
  @UseGuards(JwtGuard)
  @Post('staff/pin/change') changePin(@Req() req: any, @Body() b: ChangePinDto) {
    return this.auth.changeStaffPin(req.user.sub, b.newPin);
  }
}
