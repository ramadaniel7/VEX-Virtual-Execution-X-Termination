const base = require("./ct");
const { SlashCommandBuilder } = require("discord.js");
module.exports = { data: new SlashCommandBuilder().setName("checktimer").setDescription("Cek timer license (alias /ct)").addStringOption(o=>o.setName("placeid").setDescription("Place ID").setRequired(true)), execute: base.execute };
