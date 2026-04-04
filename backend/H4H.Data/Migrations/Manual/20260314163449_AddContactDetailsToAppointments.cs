using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace H4H.Data.Migrations.Manual
{
    /// <inheritdoc />
    public partial class AddContactDetailsToAppointments : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "contact_name",
                table: "appointments",
                type: "character varying(200)",
                maxLength: 200,
                nullable: true); // na początek dajemy true, żeby nie było błędów ze starymi danymi

            migrationBuilder.AddColumn<string>(
                name: "contact_phone_number",
                table: "appointments",
                type: "character varying(20)",
                maxLength: 20,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "contact_email",
                table: "appointments",
                type: "character varying(150)",
                maxLength: 150,
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "contact_name",
                table: "appointments");

            migrationBuilder.DropColumn(
                name: "contact_phone_number",
                table: "appointments");

            migrationBuilder.DropColumn(
                name: "contact_email",
                table: "appointments");
        }
    }
}
