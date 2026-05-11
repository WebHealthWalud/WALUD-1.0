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
    // Roles
    Role::firstOrCreate(['name' => 'paciente', 'guard_name' => 'api']);
    Role::firstOrCreate(['name' => 'medico',   'guard_name' => 'api']);
    Role::firstOrCreate(['name' => 'admin',    'guard_name' => 'api']);

    // Permisos — cambia todos los Permission::create por Permission::firstOrCreate
    Permission::firstOrCreate(['name' => 'ver citas',      'guard_name' => 'api']);
    Permission::firstOrCreate(['name' => 'crear citas',    'guard_name' => 'api']);
    Permission::firstOrCreate(['name' => 'cancelar citas', 'guard_name' => 'api']);
    // ... el resto de permisos que tengas, todos con firstOrCreate
}
}
