using System.Drawing.Imaging;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using AppAPI.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.IdentityModel.Tokens;
using QRCoder;

namespace AppAPI.Controllers {
    [ApiController]
    [Route("api/[controller]")]
    public class AccountController : ControllerBase {
        private readonly UserManager<ApplicationUser> _userManager;
        private readonly IConfiguration _configuration;

        public AccountController(UserManager<ApplicationUser> userManager, IConfiguration configuration) {
            _userManager = userManager;
            _configuration = configuration;
            System.Diagnostics.Debug.WriteLine("Using database path: " + _configuration.GetConnectionString("DefaultConnection"));
        }

        [HttpPost("register")]
        public async Task<IActionResult> Register([FromBody] RegisterUserModel model) {
            if (!ModelState.IsValid) {
                return BadRequest(ModelState);
            }

            var user = new ApplicationUser {
                UserName = model.Email,
                Email = model.Email,
                FirstName = model.FirstName,
                LastName = model.LastName,
                PhoneNumber = model.PhoneNumber
            };
            // PasswordHasher can be customized in startup code for example adding:
            // services.Configure<PasswordHasherOptions>(opt => opt.IterationCount = 210_000);
            // OWASP recommends for PBKDF2-HMAC-SHA512: 210,000 iterations
            var result = await _userManager.CreateAsync(user, model.Password);

            if (result.Succeeded) {
                // TODO send an email confirmation
                return Ok("User registered successfully");
            } else {
                foreach (var error in result.Errors) {
                    ModelState.AddModelError("", error.Description);
                }
                return BadRequest(ModelState);
            }
        }

        [HttpPost("login")]
        public async Task<IActionResult> Login([FromBody] LoginUserModel model) {
            if (!ModelState.IsValid) {
                return BadRequest(ModelState);
            }

            var user = await _userManager.FindByEmailAsync(model.Email);
            if (user == null) {
                return Unauthorized("Login failed: Invalid email or password.");
            }

            if (!await _userManager.CheckPasswordAsync(user, model.Password)) {
                return Unauthorized("Login failed: Invalid email or password.");
            }

            if (user.TwoFactorEnabled) {
                return Ok(new { RequiresMfa = true }); // two factor enabled
            }
            JwtSecurityToken token = GenerateJwtToken(user);
            var encodedToken = new JwtSecurityTokenHandler().WriteToken(token);

            return Ok(new { token = encodedToken, expiration = token.ValidTo });
        }

        [HttpPost("verify-mfa")]
        public async Task<IActionResult> VerifyMfa([FromBody] MfaVerificationModel model) {
            var user = await _userManager.FindByEmailAsync(model.Email);
            if (user == null || !await _userManager.VerifyTwoFactorTokenAsync(user, _userManager.Options.Tokens.AuthenticatorTokenProvider, model.Token)) {
                return Unauthorized("Invalid MFA token.");
            }

            // Update TwoFactorEnabled to true.
            user.TwoFactorEnabled = true;
            await _userManager.UpdateAsync(user);

            // Generate JWT after MFA verification.
            JwtSecurityToken token = GenerateJwtToken(user);

            var encodedToken = new JwtSecurityTokenHandler().WriteToken(token);
            return Ok(new { token = encodedToken, expiration = token.ValidTo });
        }

        private JwtSecurityToken GenerateJwtToken(ApplicationUser? user) {
            var securityKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_configuration["Jwt:Key"]));
            var credentials = new SigningCredentials(securityKey, SecurityAlgorithms.HmacSha256);
            var claims = new[] {
               new Claim(JwtRegisteredClaimNames.Sub, user.Email),
               new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString()),
            };

            var token = new JwtSecurityToken(
            issuer: _configuration["Jwt:Issuer"],
            audience: _configuration["Jwt:Audience"],
            claims: claims,
            expires: DateTime.Now.AddHours(3),
            signingCredentials: credentials
            );
            return token;
        }

        [HttpGet("settings")]
        [Authorize]
        public async Task<IActionResult> GetSettings() {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            var user = await _userManager.FindByEmailAsync(userId);

            if (user == null) {
                return Unauthorized();
            }

            return Ok(new {
                isMfaEnabled = user.TwoFactorEnabled,
            });
        }

        [HttpPost("settings/mfa")]
        [Authorize]
        public async Task<IActionResult> UpdateMfaSetting([FromBody] UserSettingsModel model) {
            if (!ModelState.IsValid) {
                return BadRequest(ModelState);
            }

            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            var user = await _userManager.FindByEmailAsync(userId);

            if (user == null) {
                return Unauthorized();
            }

            user.TwoFactorEnabled = model.IsMfaEnabled;
            var result = await _userManager.UpdateAsync(user);

            if (!result.Succeeded) {
                return BadRequest("Failed to update MFA setting.");
            }

            return Ok(new { message = "MFA setting updated successfully" });
        }

        [HttpPost("enroll-mfa")]
        [Authorize]
        public async Task<IActionResult> EnrollMfa() {
            var userId = User.FindFirstValue(ClaimTypes.NameIdentifier);
            var user = await _userManager.FindByEmailAsync(userId);
            if (user == null) {
                return Unauthorized("User not found.");
            }

            if (user.TwoFactorEnabled) {
                return BadRequest("MFA is already enabled.");
            }

            // Unique secret key for the user.
            var unformattedKey = await _userManager.GetAuthenticatorKeyAsync(user);
            if (string.IsNullOrEmpty(unformattedKey)) {
                await _userManager.ResetAuthenticatorKeyAsync(user);
                unformattedKey = await _userManager.GetAuthenticatorKeyAsync(user);
            }

            // Create QR Code URL.
            var email = await _userManager.GetEmailAsync(user);
            var authenticatorUri = GenerateQrCodeUri(email, unformattedKey);

            // QR code image.
            using (var qrGenerator = new QRCodeGenerator())
            using (var qrCodeData = qrGenerator.CreateQrCode(authenticatorUri, QRCodeGenerator.ECCLevel.Q))
            using (var qrCode = new QRCode(qrCodeData))
            using (var qrCodeImage = qrCode.GetGraphic(20))
            using (var ms = new MemoryStream()) {
                qrCodeImage.Save(ms, ImageFormat.Png);
                var base64Image = Convert.ToBase64String(ms.ToArray());
                return Ok(new {
                    Secret = unformattedKey,
                    QrCodeBase64 = base64Image
                });
            }
        }

        private string GenerateQrCodeUri(string email, string unformattedKey) {
            string issuer = "AppName";  // TODO replace
            string algorithm = "SHA1";  // SHA1 is ok for TOTP
            int digits = 6;  // Show 6 digits
            int period = 30;  // The TOTP code changes every 30 seconds

            // This is a standard URL format for TOTP to be used in QR Code generation
            return $"otpauth://totp/{issuer}:{email}?secret={unformattedKey}&issuer={issuer}&algorithm={algorithm}&digits={digits}&period={period}";
        }



    }

}
