using System.ComponentModel.DataAnnotations;

namespace AppAPI.Models
{
    public class RegisterUserModel
    {
        [Required]
        [EmailAddress]
        public string Email { get; set; }

        [Required]
        [StringLength(100, ErrorMessage = "The {0} must be at least {2} characters long.", MinimumLength = 6)]
        [DataType(DataType.Password)]
        public string Password { get; set; }

        [DataType(DataType.Password)]
        [Compare("Password", ErrorMessage = "The passwords entered do not match.")]
        public string ConfirmPassword { get; set; }

        [Required]
        [StringLength(50, ErrorMessage = "The {0} must be at most {1} characters long.")]
        public string FirstName { get; set; }

        [Required]
        [StringLength(50, ErrorMessage = "The {0} must be at most {1} characters long.")]
        public string LastName { get; set; }

        [StringLength(15)]
        [RegularExpression(@"^\+?[1-9]\d{1,14}$", ErrorMessage = "The {0} entered is not valid.")]
        public string PhoneNumber { get; set; }
    }
}
