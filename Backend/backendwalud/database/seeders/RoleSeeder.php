<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Spatie\Permission\Models\Role;
use Spatie\Permission\Models\Permission;

class RoleSeeder extends Seeder
{
    public function run(): void
    {
        // Crear roles
        $rolePaciente = Role::create(['name' => 'paciente', 'guard_name' => 'api']);
        $roleMedico = Role::create(['name' => 'medico', 'guard_name' => 'api']);
        $roleAdmin = Role::create(['name' => 'admin', 'guard_name' => 'api']);

        // Permisos básicos
        Permission::create(['name' => 'ver citas', 'guard_name' => 'api']);
        Permission::create(['name' => 'crear citas', 'guard_name' => 'api']);
        Permission::create(['name' => 'editar citas', 'guard_name' => 'api']);
        Permission::create(['name' => 'eliminar citas', 'guard_name' => 'api']);
    }
}
