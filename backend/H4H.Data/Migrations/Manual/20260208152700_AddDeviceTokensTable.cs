using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace H4H.Data.Migrations.Manual
{
    /// <inheritdoc />
    public partial class AddDeviceTokensTable : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "device_tokens",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    user_id = table.Column<Guid>(type: "uuid", nullable: false),
                    fcm_token = table.Column<string>(type: "text", nullable: false),
                    last_used_at = table.Column<DateTime>(type: "timestamp without time zone", nullable: false),
                    created_at = table.Column<DateTime>(type: "timestamp without time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_device_tokens", x => x.id);
                    table.ForeignKey(
                        name: "FK_device_tokens_users_user_id",
                        column: x => x.user_id,
                        principalTable: "users",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "idx_device_tokens_fcm_token",
                table: "device_tokens",
                column: "fcm_token");

            migrationBuilder.CreateIndex(
                name: "idx_device_tokens_user",
                table: "device_tokens",
                column: "user_id");

            migrationBuilder.CreateIndex(
                name: "IX_device_tokens_user_id_fcm_token",
                table: "device_tokens",
                columns: new[] { "user_id", "fcm_token" },
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "device_tokens");
        }
    }
}
