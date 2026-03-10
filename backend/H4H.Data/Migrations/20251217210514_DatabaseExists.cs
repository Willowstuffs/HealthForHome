using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace H4H.Data.Migrations
{
    /// <inheritdoc />
    public partial class DatabaseExists : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // nie tworzymy tabel, bo już istnieją
            // EF tylko doda wpis do __EFMigrationsHistory
        }

        protected override void Down(MigrationBuilder migrationBuilder)
        {
            // nie usuwamy istniejących tabel
        }
    }
}