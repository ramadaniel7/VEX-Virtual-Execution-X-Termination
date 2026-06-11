const base = require("./cs");
const { SlashCommandBuilder } = require("discord.js");
module.exports = { data: new SlashCommandBuilder().setName("checkstatus").setDescription("Cek status license VEX (alias /cs)").addStringOption(o=>o.setName("placeid").setDescription("Place ID").setRequired(true)), execute: base.execute };
