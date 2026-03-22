import { config } from './config.ts'
import { OpenRouterService } from './openrouterService.ts'
import { createServer } from './server.ts'

const routerService = new OpenRouterService(config)
const app = createServer(routerService)

await app.listen({ port: 3000, host: '0.0.0.0' })
console.log('Server runing at 3000')
