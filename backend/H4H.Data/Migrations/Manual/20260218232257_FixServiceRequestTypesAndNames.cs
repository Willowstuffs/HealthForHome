using Microsoft.EntityFrameworkCore.Migrations;
using NetTopologySuite.Geometries;

#nullable disable

namespace H4H.Data.Migrations.Manual
{
    /// <inheritdoc />
    public partial class FixServiceRequestTypesAndNames : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_service_requests_clients_ClientId",
                table: "service_requests");

            migrationBuilder.DropForeignKey(
                name: "FK_service_requests_service_types_ServiceTypeId",
                table: "service_requests");

            migrationBuilder.RenameColumn(
                name: "Status",
                table: "service_requests",
                newName: "status");

            migrationBuilder.RenameColumn(
                name: "Location",
                table: "service_requests",
                newName: "location");

            migrationBuilder.RenameColumn(
                name: "Email",
                table: "service_requests",
                newName: "email");

            migrationBuilder.RenameColumn(
                name: "Description",
                table: "service_requests",
                newName: "description");

            migrationBuilder.RenameColumn(
                name: "Address",
                table: "service_requests",
                newName: "address");

            migrationBuilder.RenameColumn(
                name: "Id",
                table: "service_requests",
                newName: "id");

            migrationBuilder.RenameColumn(
                name: "UpdatedAt",
                table: "service_requests",
                newName: "updated_at");

            migrationBuilder.RenameColumn(
                name: "ServiceTypeId",
                table: "service_requests",
                newName: "service_type_id");

            migrationBuilder.RenameColumn(
                name: "PhoneNumber",
                table: "service_requests",
                newName: "phone_number");

            migrationBuilder.RenameColumn(
                name: "MaxPrice",
                table: "service_requests",
                newName: "max_price");

            migrationBuilder.RenameColumn(
                name: "DateTo",
                table: "service_requests",
                newName: "date_to");

            migrationBuilder.RenameColumn(
                name: "DateFrom",
                table: "service_requests",
                newName: "date_from");

            migrationBuilder.RenameColumn(
                name: "CreatedAt",
                table: "service_requests",
                newName: "created_at");

            migrationBuilder.RenameColumn(
                name: "ContactName",
                table: "service_requests",
                newName: "contact_name");

            migrationBuilder.RenameColumn(
                name: "ClientId",
                table: "service_requests",
                newName: "client_id");

            migrationBuilder.RenameIndex(
                name: "IX_service_requests_ServiceTypeId",
                table: "service_requests",
                newName: "IX_service_requests_service_type_id");

            migrationBuilder.RenameIndex(
                name: "IX_service_requests_ClientId",
                table: "service_requests",
                newName: "IX_service_requests_client_id");

            migrationBuilder.AlterColumn<Point>(
                name: "location",
                table: "service_requests",
                type: "geography(Point, 4326)",
                nullable: false,
                oldClrType: typeof(Point),
                oldType: "geography(Point, 4326)",
                oldNullable: true);

            migrationBuilder.AlterColumn<string>(
                name: "email",
                table: "service_requests",
                type: "text",
                nullable: false,
                defaultValue: "",
                oldClrType: typeof(string),
                oldType: "text",
                oldNullable: true);

            migrationBuilder.AlterColumn<string>(
                name: "phone_number",
                table: "service_requests",
                type: "text",
                nullable: false,
                defaultValue: "",
                oldClrType: typeof(string),
                oldType: "text",
                oldNullable: true);

            migrationBuilder.AlterColumn<string>(
                name: "contact_name",
                table: "service_requests",
                type: "text",
                nullable: false,
                defaultValue: "",
                oldClrType: typeof(string),
                oldType: "text",
                oldNullable: true);

            migrationBuilder.AddForeignKey(
                name: "FK_service_requests_clients_client_id",
                table: "service_requests",
                column: "client_id",
                principalTable: "clients",
                principalColumn: "id",
                onDelete: ReferentialAction.SetNull);

            migrationBuilder.AddForeignKey(
                name: "FK_service_requests_service_types_service_type_id",
                table: "service_requests",
                column: "service_type_id",
                principalTable: "service_types",
                principalColumn: "id",
                onDelete: ReferentialAction.Cascade);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_service_requests_clients_client_id",
                table: "service_requests");

            migrationBuilder.DropForeignKey(
                name: "FK_service_requests_service_types_service_type_id",
                table: "service_requests");

            migrationBuilder.RenameColumn(
                name: "status",
                table: "service_requests",
                newName: "Status");

            migrationBuilder.RenameColumn(
                name: "location",
                table: "service_requests",
                newName: "Location");

            migrationBuilder.RenameColumn(
                name: "email",
                table: "service_requests",
                newName: "Email");

            migrationBuilder.RenameColumn(
                name: "description",
                table: "service_requests",
                newName: "Description");

            migrationBuilder.RenameColumn(
                name: "address",
                table: "service_requests",
                newName: "Address");

            migrationBuilder.RenameColumn(
                name: "id",
                table: "service_requests",
                newName: "Id");

            migrationBuilder.RenameColumn(
                name: "updated_at",
                table: "service_requests",
                newName: "UpdatedAt");

            migrationBuilder.RenameColumn(
                name: "service_type_id",
                table: "service_requests",
                newName: "ServiceTypeId");

            migrationBuilder.RenameColumn(
                name: "phone_number",
                table: "service_requests",
                newName: "PhoneNumber");

            migrationBuilder.RenameColumn(
                name: "max_price",
                table: "service_requests",
                newName: "MaxPrice");

            migrationBuilder.RenameColumn(
                name: "date_to",
                table: "service_requests",
                newName: "DateTo");

            migrationBuilder.RenameColumn(
                name: "date_from",
                table: "service_requests",
                newName: "DateFrom");

            migrationBuilder.RenameColumn(
                name: "created_at",
                table: "service_requests",
                newName: "CreatedAt");

            migrationBuilder.RenameColumn(
                name: "contact_name",
                table: "service_requests",
                newName: "ContactName");

            migrationBuilder.RenameColumn(
                name: "client_id",
                table: "service_requests",
                newName: "ClientId");

            migrationBuilder.RenameIndex(
                name: "IX_service_requests_service_type_id",
                table: "service_requests",
                newName: "IX_service_requests_ServiceTypeId");

            migrationBuilder.RenameIndex(
                name: "IX_service_requests_client_id",
                table: "service_requests",
                newName: "IX_service_requests_ClientId");

            migrationBuilder.AlterColumn<Point>(
                name: "Location",
                table: "service_requests",
                type: "geography(Point, 4326)",
                nullable: true,
                oldClrType: typeof(Point),
                oldType: "geography(Point, 4326)");

            migrationBuilder.AlterColumn<string>(
                name: "Email",
                table: "service_requests",
                type: "text",
                nullable: true,
                oldClrType: typeof(string),
                oldType: "text");

            migrationBuilder.AlterColumn<string>(
                name: "PhoneNumber",
                table: "service_requests",
                type: "text",
                nullable: true,
                oldClrType: typeof(string),
                oldType: "text");

            migrationBuilder.AlterColumn<string>(
                name: "ContactName",
                table: "service_requests",
                type: "text",
                nullable: true,
                oldClrType: typeof(string),
                oldType: "text");

            migrationBuilder.AddForeignKey(
                name: "FK_service_requests_clients_ClientId",
                table: "service_requests",
                column: "ClientId",
                principalTable: "clients",
                principalColumn: "id",
                onDelete: ReferentialAction.SetNull);

            migrationBuilder.AddForeignKey(
                name: "FK_service_requests_service_types_ServiceTypeId",
                table: "service_requests",
                column: "ServiceTypeId",
                principalTable: "service_types",
                principalColumn: "id",
                onDelete: ReferentialAction.Cascade);
        }
    }
}
