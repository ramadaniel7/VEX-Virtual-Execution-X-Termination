// bot/index.js — VEX Bot v2
require("dotenv").config();
const { Client, GatewayIntentBits, Collection, REST, Routes, EmbedBuilder, ActionRowBuilder, ButtonBuilder, ButtonStyle } = require("discord.js");
const fetch   = require("node-fetch");
const fs      = require("fs");
const path    = require("path");
const { handleMemberLeave, handleMemberLeaveButtons } = require("./handlers/memberLeave");

const client = new Client({
  intents: [
    GatewayIntentBits.Guilds,
    GatewayIntentBits.GuildMessages,
    GatewayIntentBits.GuildMembers,
    GatewayIntentBits.DirectMessages,
  ]
});

client.commands = new Collection();
const cmdData  = [];

for (const file of fs.readdirSync(path.join(__dirname, "commands")).filter(f => f.endsWith(".js"))) {
  const cmd = require(`./commands/${file}`);
  client.commands.set(cmd.data.name, cmd);
  cmdData.push(cmd.data.toJSON ? cmd.data.toJSON() : cmd.data);
}

// ── Ready ────────────────────────────────────────────────────
client.once("ready", async () => {
  console.log(`[VEX] Online: ${client.user.tag}`);
  const rest = new REST({ version: "10" }).setToken(process.env.DISCORD_TOKEN);
  await rest.put(Routes.applicationCommands(process.env.CLIENT_ID), { body: cmdData });
  console.log("[VEX] Commands deployed.");
  client.user.setPresence({ activities: [{ name: "🛡️ VEX Anti-Cheat | /help", type: 3 }], status: "online" });
  startRenewalReminder();
});

// ── Interactions ──────────────────────────────────────────────
client.on("interactionCreate", async (interaction) => {
  if (interaction.isChatInputCommand()) {
    const cmd = client.commands.get(interaction.commandName);
    if (!cmd) return;
    try { await cmd.execute(interaction); }
    catch (e) {
      console.error(e);
      const msg = { embeds: [new EmbedBuilder().setColor(0xFF0000).setTitle("❌ Error").setDescription("Terjadi error, coba lagi.")], ephemeral: true };
      interaction.replied || interaction.deferred ? interaction.followUp(msg) : interaction.reply(msg);
    }
  }
  if (interaction.isButton()) await handleMemberLeaveButtons(interaction);
});

// ── Member Leave ──────────────────────────────────────────────
client.on("guildMemberRemove", async (member) => handleMemberLeave(member, client));

// ── Renewal Reminder ──────────────────────────────────────────
const BOT_START = Date.now();
let reminderSent = false;

function startRenewalReminder() {
  const ms = (parseInt(process.env.RENEWAL_REMINDER_HOURS) || 22) * 3600000;
  setInterval(async () => {
    if (reminderSent || Date.now() - BOT_START < ms) return;
    reminderSent = true;
    try {
      const ch    = await client.channels.fetch(process.env.ADMIN_CHANNEL_ID);
      const owner = await client.users.fetch(process.env.OWNER_DISCORD_ID);
      const embed = new EmbedBuilder().setColor(0xFF8800).setTitle("⏰ RENEWAL SERVER REMINDER")
        .setDescription("**Server bot VEX hampir 24 jam! Segera renewal di panel Fps.ms agar bot tidak offline.**")
        .addFields({ name: "⏱️ Uptime", value: `${process.env.RENEWAL_REMINDER_HOURS || 22} jam` })
        .setTimestamp();
      const row = new ActionRowBuilder().addComponents(
        new ButtonBuilder().setLabel("Buka Panel Fps.ms").setURL("https://fps.ms/panel").setStyle(ButtonStyle.Link)
      );
      await owner.send({ embeds: [embed], components: [row] }).catch(() => {});
      await ch.send({ content: `⚠️ <@${process.env.OWNER_DISCORD_ID}> <@&${process.env.ADMIN_ROLE_ID}> <@&${process.env.ADMIN_ROLE2_ID}> **SERVER PERLU RENEWAL!**`, embeds: [embed], components: [row] });
    } catch(e) { console.error("[VEX] Renewal reminder error:", e.message); }
  }, 30 * 60000);
}

// ── API helper (dipakai commands) ─────────────────────────────
module.exports.api = async (endpoint, method = "GET", body = null) => {
  const opts = { method, headers: { "Content-Type": "application/json", "x-bot-secret": process.env.BOT_SECRET } };
  if (body) opts.body = JSON.stringify(body);
  const res = await fetch(process.env.BACKEND_URL + endpoint, opts);
  return res.json();
};

client.login(process.env.DISCORD_TOKEN);
