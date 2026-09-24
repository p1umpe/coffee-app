import { Controller, Get } from '@nestjs/common';
@Controller('health')
export class HealthController {
  @Get() ok() { return { ok: true, service: 'simple-coffee-api', version: '0.2.0' }; }
}
