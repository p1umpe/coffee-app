import { Body, Controller, Post } from '@nestjs/common';
import { IsString, MinLength } from 'class-validator';
import { AuthService } from './auth.service';
class PhoneDto { @IsString() @MinLength(6) phone!: string; }
class VerifyDto { @IsString() phone!: string; @IsString() @MinLength(4) code!: string; }
@Controller('auth')
export class AuthController {
  constructor(private auth: AuthService) {}
  @Post('otp/request') request(@Body() b: PhoneDto) { return this.auth.requestOtp(b.phone); }
  @Post('otp/verify') verify(@Body() b: VerifyDto) { return this.auth.verifyOtp(b.phone, b.code); }
}
